mwupload.pl

Upload images in a directory to a Mediawiki site.

* Iterative resizing

If some of your images are too large to upload you can alternate between these commands:

$ mwupload.pl -c myconfig.yaml -i ~/myimages --delete -m "Photos by N.N. [[Category:Holiday]]"
$ for i in *.jpg; do convert "$i" -resize 90% "$i"; done
