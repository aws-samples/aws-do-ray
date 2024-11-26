from io import BytesIO
from fastapi import FastAPI
from fastapi.responses import Response
import numpy as np
import cv2
import random
from ray import serve
from ray.serve.handle import DeploymentHandle
from stable_diffusion_cpu_engine import StableDiffusionEngine
from diffusers import LMSDiscreteScheduler, PNDMScheduler
from PIL import Image

app = FastAPI()

@serve.deployment(num_replicas=1)
@serve.ingress(app)
class APIIngress:
    def __init__(self, diffusion_model_handle: DeploymentHandle) -> None:
        self.handle = diffusion_model_handle

    @app.get(
        "/imagine",
        responses={200: {"content": {"image/png": {}}}},
        response_class=Response,
    )
    async def generate(self, prompt: str, img_size: int = 512):
        assert len(prompt), "prompt parameter cannot be empty"

        image = await self.handle.generate.remote(prompt, img_size=img_size)
        file_stream = BytesIO()
        image.save(file_stream, "PNG")
        return Response(content=file_stream.getvalue(), media_type="image/png")


@serve.deployment(
    # ray_actor_options={"num_cpus": 3},  # Adjust CPU cores according to needs
    autoscaling_config={"min_replicas": 1, "max_replicas": 2},
)
class StableDiffusionV2:
    def __init__(self):
        # Scheduler Selection
        self.scheduler = LMSDiscreteScheduler(
            beta_start=0.00085,
            beta_end=0.012,
            beta_schedule="scaled_linear",
        )
        # Load Stable Diffusion Model
        self.engine = StableDiffusionEngine(
            model="bes-dev/stable-diffusion-v1-4-openvino",
            scheduler=self.scheduler,
            tokenizer="openai/clip-vit-large-patch14",
            device="CPU"
        )

    def generate(self, prompt: str, img_size: int = 512):
        assert len(prompt), "prompt parameter cannot be empty"

        # Set random seed for reproducibility
        seed = random.randint(0, 2**30)
        np.random.seed(seed)

        # Run Inference
        image = self.engine(
            prompt=prompt,
            init_image=None,
            mask=None,
            strength=0.5,
            num_inference_steps=32,
            guidance_scale=7.5,
            eta=0.0
        )
        # Convert to PIL image for serving
        image = cv2.cvtColor(image, cv2.COLOR_BGR2RGB)
        image = Image.fromarray(image)
        return image


entrypoint = APIIngress.bind(StableDiffusionV2.bind())

