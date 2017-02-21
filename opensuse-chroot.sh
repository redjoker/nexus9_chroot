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

*)
     echo "

Usage: $0 [ start | stop ]

"
     ;;
esac
