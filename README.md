# ConfyUI for Docker with CUDA and pre-loaded models

I made this project because I wanted a simple, easy solution to setup and run ComfyUI without having to manually download checkpoints or vaes everywhere. And I wanted a Docker solution to make everything clean in my machine.

```
git clone https://github.com/akitaonrails/ComfyUI-Docker-CUDA-preloaded.git
cd ComfyUI-Docker-CUDA-preloaded
docker compose build
```

Now, pay attention to [init_models.sh](init_scripts/init_models.sh). It is an entrypoint script for this docker container. It means it will run every time the container loads. It's function is to download many famous models, so we don't have to manually hunt for them (contributions are welcome).

Problem is, if you download everything, be prepared to wait for a VERY LONG TIME and see **250GB** of your hard-drive be eaten up. Yes, the models are HUGE, some of them have 25GB or more.

Yes, if you are serious, this shouldn't be a problem. But if you don't want all of those, you can edit the [models.conf](models.conf) and remove (remove, not comment out) the ones you don't need, then re-build the image.

If you're ok, just run:

```
# just the first time or if you change anything about the image build
docker compose up -d --build

# subsequent runs:
docker compose up -d

# to stop it:
docker compose down
```

Directories such as input, output and models are exposed as external volumes, so after the download, the container won't download everything again. The init_models.sh script is smart enough to skip files that were already downloaded. So, if you want to include new models, just add them to this script. It's more organized, and next time you reinstall, you will be able to fetch them all over again.

I included several known models such as SDXL, Flux, Hunyuon and more. There is also a secondary [extensions.conf](extensions.conf) - used by [init_scripts/init_extensions.sh] where I pre-configured all recommendations from Aitrepreneurs Ultimate ComfyUI configuration. You can add your own extensions here instead of manually, and unreliably, using ComfyUI Manager in the WebUI.

## Extensions

ComfyUI allows you to install external extensions, which will add a bunch of new functionality, new nodes and more. Some workflows require that. ComfyUI Manager is pre-installed.

I recommend you add new extensions to the list in [extensions.conf](extensions.conf) that way, every time you restart the container, it will automatically update (git pull) and install dependencies (pip install).

Because extensions require python dependencies of their own, I configured "/venv" to be a Docker Volume. If you ever run into problems with dangling dependencies from older versions of some extensions, you can always wipe this volume clean. Next time the container restarts, it will reinstall them from all extensions.

```
docker compose down # otherwise a dangling running container my be locking the volume
docker volume rm comfyui_venv
```

This should be enough to resolve future dependencies problems.

Example use case: I was previously using a ubuntu22 base image, but I changed to ubuntu24 because some extensions break with python3.11 and they require python3.12. After I updated the Dockerfile I deleted the VENV volume so the Python would download newer pip packages there and then the extensions would re-resolve all dependencies again on container restart.
