# make first
# make run
# make clean

curdir = $(shell pwd)

run:

	docker start -ia jekyll

stop:
	docker stop jekyll

runfirst:
	docker run --name jekyll --volume=$(curdir):/srv/jekyll \
	  -it --network host jekyll/jekyll jekyll serve --draft

clean:
	docker rm jekyll
