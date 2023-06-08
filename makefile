FBC=fbc #compiler
PRIMARY=Nebunoid #primary file (main program)
SECONDARY=NebEdit #secondary file (level editor)

all:
	$(FBC) -x $(PRIMARY) -s gui Nebunoid.bas
	$(FBC) -x $(SECONDARY) -s gui NebEdit.bas
	
clean:
	rm *.o $(PRIMARY) $(SECONDARY)
