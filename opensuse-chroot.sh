#!/sbin/sh

ROOTDEV=${ROOTDEV:-/storage/emulated/0/nexus9_chroot/opensuse.img}
ROOT=${ROOT:-/storage/emulated/0/nexus9_chroot/opensuse}
ROOTMNTOPTS='-t ext4 -o loop'

ACTION=${1:-start}

case $ACTION in

start)
     ## needs to run once to setup the chroot environment
  
          echo -n "Mounting: $ROOTMNTOPTS $ROOTDEV $ROOT"
          busybox mount $ROOTMNTOPTS $ROOTDEV $ROOT \
               && echo OK \
               || echo FAIL

          echo -n " Mounting proc $ROOT/proc... "
          busybox mount -t proc proc $ROOT/proc \
               && echo OK \
               || echo FAIL

          echo -n " Mounting sysfs $ROOT/sys... "
          busybox mount -t sysfs sysfs $ROOT/sys \
               && echo OK \
               || echo FAIL

          echo -n " Mounting /dev/ $ROOT/dev... "
          busybox mount -o bind /dev/ $ROOT/dev \
               && echo OK \
               || echo FAIL


          echo -n " Mounting devpts $ROOT/dev/pts... "
          busybox mount -t devpts devpts $ROOT/dev/pts \
               && echo OK \
               || echo FAIL

          echo -n " Mounting /sdcard $ROOT/root/Android... "
          busybox mount -o bind $ROOT/../.. $ROOT/root/Android \
               && echo OK \
               || echo FAIL

     ## needs to run every time a new terminal session is created

     echo "Setting env variables: PS1 PATH HOME"
     export PS1='\u@\h \w\n\$ '
     export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin
     export HOME=/root
     am start x.org.server/.MainActivity
     echo "Chroot-ing to $ROOT/"
     busybox chroot $ROOT/ /bin/su -
     ;;

stop)
     for d in root/Android dev/pts dev sys proc .
     do
          echo -n "Unmounting: $ROOT/$d... "
          busybox umount $ROOT/$d \
               && echo OK \
               || echo FAIL
     done
     am kill x.org.server \
          && echo OK \
          || am force-stop x.org.server \
               && echo OK \
               || echo FAIL 
     ;;


install)
     ## get latest rootfs tarball, create disk image, format, extract to image
          echo -n "Set up directory"
          mkdir $ROOT \
               && echo OK \
               || echo FAIL
          
          echo -n "Downloading tarball from openSUSE"
          curl --metalink http://download.opensuse.org/ports/aarch64/tumbleweed/images/openSUSE-Tumbleweed-ARM-XFCE.aarch64-rootfs.aarch64-Current.tbz.meta4 > openSUSE-Tumbleweed-ARM-XFCE.aarch64-rootfs.aarch64-Current.tar.bz2 \
               && echo OK \
               || echo FAIL
          
          echo -n "Create disk image at $ROOTDEV"
          busybox dd if=/dev/zero of=$ROOTDEV bs=1024 count=8388608 \
               && echo OK \
               || echo FAIL
          
          echo -n "Format disk image at $ROOTDEV to ext4"
          busybox mke2fs -t ext4 $ROOTDEV \
               && echo OK \
               || echo FAIL
               
          echo -n "Mounting: $ROOTMNTOPTS $ROOTDEV $ROOT"
          busybox mount $ROOTMNTOPTS $ROOTDEV $ROOT \
               && echo OK \
               || echo FAIL
          
          echo -n "Extracting tarball to $ROOT"
          cd $ROOT
          busybox tar xvjf ../openSUSE-Tumbleweed-ARM-XFCE.aarch64-rootfs.aarch64-Current.tar.bz2 . \
               && echo OK \
               || echo FAIL

          echo -n "Copy graphics script to $ROOT/root/"
          cp $ROOT/../graphics.sh $ROOT/root/graphics.sh \
               && echo OK \
               || echo FAIL
               

     ;;

*)
     echo "

Usage: $0 [ start | stop | install]

"
     ;;
esac
