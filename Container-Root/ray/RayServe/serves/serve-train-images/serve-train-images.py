import argparse
import json
import logging
import os

import torch
from ray import serve
from transformers import AutoConfig, AutoImageProcessor, AutoModelForImageClassification

from PIL import Image

import requests

from torchvision.transforms import (
    CenterCrop,
    Compose,
    Normalize,
    RandomHorizontalFlip,
    RandomResizedCrop,
    Resize,
    ToTensor,
)

logging.basicConfig(level=logging.INFO)


# def parse_args():
#     parser = argparse.ArgumentParser(description="Serve a fine-tuned Transformers model on an image classification dataset")
#     # parser.add_argument("--model_dir", type=str, default="s3://eks-ray-bucket/run_configs/train_images-ray/TorchTrainer_a0880_00000_0_2024-06-10_16-17-38/checkpoint_000000/model.pt", required=True, help="Path to the directory containing the trained model and processor.")
#     parser.add_argument("--model_dir", type=str, default="/s3/run_configs/train_images-ray/TorchTrainer_a0880_00000_0_2024-06-10_16-17-38/checkpoint_000000/", required=True, help="Path to the directory containing the trained model and processor.")
#     parser.add_argument("--preprocessor", type=str, default="google/vit-base-patch16-224-in21k", help="Name of the preprocessor used for the model or path where config.json is for preprocessing."),
#     parser.add_argument("--port", type=int, default=8000, help="Port number to run the Ray Serve HTTP server.")
#     return parser.parse_args()


@serve.deployment
class ImageClassificationModel:
    def __init__(self, model_dir: str,  preprocessor: str):

        self.device = torch.device("cuda" if torch.cuda.is_available() else "cpu")

        model_path = os.path.join(model_dir, "pytorch_model.bin")
        config_path = os.path.join(model_dir, "config.json")
        print("Loading model from {}".format(model_path))
        print("Loading config from {}".format(config_path))

        # Load the model and processor
        self.image_processor = AutoImageProcessor.from_pretrained(preprocessor)
        print("[1/4] Loaded image processor: {}".format(self.image_processor))

        # self.config = self.model.config

        self.config = AutoConfig.from_pretrained(
            os.path.join(model_dir, "config.json")
        )
        print("[2/4] Loaded config: {}".format(self.config))

        self.model = AutoModelForImageClassification.from_pretrained(
            model_dir,
            from_tf=bool(".ckpt" in model_dir),
            # config=self.config,
            ignore_mismatched_sizes="store_false").to(self.device)
        
        print("[3/4] Loaded model: {}".format(self.model))

        self.model.eval()
        print("[4/4] Model set to evaluation mode")


        # Define torchvision transforms for validation
        if "shortest_edge" in self.image_processor.size:
            size = self.image_processor.size["shortest_edge"]
        else:
            size = (self.image_processor.size["height"], self.image_processor.size["width"])
        
        self.val_transforms = Compose(
            [
                Resize(size),
                CenterCrop(size),
                ToTensor(),
                Normalize(mean=self.image_processor.image_mean, std=self.image_processor.image_std),
            ]
        )




    async def __call__(self, starlette_request):
        # Read the image from the request
        user_request = await starlette_request.json()
        image_url = user_request.get('image_url')
        if not image_url:
            return {"error": "No image URL provided"}
        
        try:
            response = requests.get(image_url, stream=True)
            response.raise_for_status()  # Ensure we raise an exception for bad responses
            # image = Image.open(requests.get(image_url, stream=True).raw)
            image = Image.open(response.raw).convert("RGB")
        except (image.exceptions.RequestException, ValueError) as e:
            return {"error": str(e)}


        print("[1/3] Parsed image data: {}".format(image))


        # Apply validation transforms to the image
        inputs = self.val_transforms(image).unsqueeze(0).to(self.device)  # Add batch dimension
        print("[2/3] Images transformed, tensor shape: {}".format(inputs.shape))

        with torch.no_grad():
            outputs = self.model(pixel_values=inputs)
            logits = outputs.logits
            predicted_class_idx = logits.argmax(-1).item()
            predicted_class = self.config.id2label[predicted_class_idx]

        print("[3/3] Inference done!")

        return {"predicted_class": predicted_class}


# def main():
#     args = parse_args()

#     # Initialize Ray Serve
#     serve.start(http_options={"host": "0.0.0.0", "port": args.port})

#     # Deploy the model
#     # serve.deployment(name="image-classifier", route_prefix="/", num_replicas=1)(
#     #     ImageClassificationModel(args.model_dir)
#     # ).deploy()
#     model = ImageClassificationModel.bind(args.model_dir, args.preprocessor)

#     serve.run(model)



#     print(f"Model is being served at http://localhost:{args.port}")


# if __name__ == "__main__":
#     main()


model_dir = "/s3/run_configs/train_images-ray/TorchTrainer_bccd8_00000_0_2024-06-19_10-09-50/checkpoint_000000/"
preprocessor = "google/vit-base-patch16-224-in21k"

app = ImageClassificationModel.bind(model_dir, preprocessor)
