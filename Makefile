

zig: zig build -Dcpu=i386 -Dtarget=x86-freestanding

iso: 
	zig build-exe -target i386-freestanding -frosetta
	mkdir -p iso/boot/grub
	cp zig-out/bin/zmigriOS iso/boot/grub/zmigriOS
	cp grub.cfg iso/boot/grub/grub.cfg


mac:
	docker run --rm \
	-v "$(pwd):/work" \
	-w /work \
	ubuntu:22.04 \
	bash -c "apt update && apt install -y grub-pc-bin grub-common xorriso && grub-mkrescue -o os.iso iso"