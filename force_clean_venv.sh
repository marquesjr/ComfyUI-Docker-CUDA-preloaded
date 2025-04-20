docker compose down
docker volume rm comfyui-venv
rm -Rf custom_nodes/.last_commits
echo "venv cleaned, docker compose up should repopulate running pip install. if this is a catastrophic error, try rm -Rf custom_nodes to re-download them from extensions.conf"
