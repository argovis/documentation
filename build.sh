docker container run -it -v $(pwd):/src argovis/docbuilder:dev make html
cp -rf _build/html/* docs/.
