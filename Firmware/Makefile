all: miniboot.rom miniboot.burn loadsd

miniboot.obj: miniboot.s
	as11 miniboot.s -b

loadsd.obj: loadsd.s
	as11 loadsd.s -b

miniboot.rom: miniboot.obj
	dd if=miniboot.obj bs=16384 skip=3 >miniboot.tmp
	cat miniboot.tmp miniboot.tmp >miniboot.rom

loadsd: loadsd.obj
	dd if=loadsd.obj bs=384 count=1 >loadsd

mkmini11: mkmini11.c

miniboot.burn: mkmini11
	./mkmini11 <miniboot.rom >miniboot.burn

clean:
	rm -f miniboot.rom miniboot.burn miniboot.tmp
	rm -f *~ *.obj mkmini11 loadsd


