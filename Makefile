# make first
# make run
# make clean

curdir = $(shell pwd)

run:

	docker start -ia jekyll

stop:
	docker stop jekyll

first:
	docker run --name jekyll --volume=$(curdir):/srv/jekyll \
	  -it -p 127.0.0.1:4000:4000 jekyll/jekyll jekyll serve --draft

clean:
	docker rm jekyll

serve_once:
	docker run --rm --label=jekyll --volume=$(curdir):/srv/jekyll \
	  -it -p 127.0.0.1:4000:4000 jekyll/jekyll jekyll serve
