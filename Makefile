all: marc

%.mrc: %.xml
	yaz-marcdump -i marcxml -o marc $< > $@

marc: sru-test-records.mrc
