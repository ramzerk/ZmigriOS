all: compile 

compile :
	zig build -Dcpu=i386 -Dtarget=x86-freestanding

iso: compile
	mkdir -p boot/grub
	cp zig-out/bin/ZmigriOS boot/grub/ZmigriOS
	cp grub.cfg boot/grub/grub.cfg


mac:
	docker run --rm \
	-v "$$(pwd):/work" \
	-w /work \
	ubuntu:22.04 \
	bash -c "apt update && apt install -y grub-pc-bin grub-common xorriso && grub-file --is-x86-multiboot ZimgriOS ;grub-mkrescue -o ZmigriOS.iso iso "

qemu: 
	qemu-system-i386 -cdrom ZmigriOS.iso