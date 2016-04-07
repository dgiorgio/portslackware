ARCH=`uname -m`

source $TOTAL_DIR/$PRGNAM.info
VERSION_INSTALL=$(echo $VERSION | sed 's/-/_/g')

sed -i 's/${TAG:-_SBo}/${TAG:-_PSl}/g' $PRGNAM.SlackBuild
sed -i "s/tgz/$TGZ_TXZ/g" $PRGNAM.SlackBuild

LOG(){
  case $1 in
    install)
      echo "$(date +%Y%m%d_%H%M) install $(ls /tmp/$PRGNAM-$VERSION_INSTALL-*-*.$TGZ_TXZ)" >> $LOG_DIR/$LOG_PORTSCRIPT
      ;;
    remove)
      echo "$(date +%Y%m%d_%H%M) remove /tmp/$PRGNAM-$VERSION_INSTALL" >> $LOG_DIR/$LOG_PORTSCRIPT
      ;;
    error)
      echo "$(date +%Y%m%d_%H%M) ERROR $PRGNAM-$VERSION" >> $LOG_DIR/$LOG_PORTSCRIPT
      ;;
  esac
}

ERROR(){
  LOG error
  echo $PRGNAM-$VERSION
  exit 1
}

CHECKS(){
  cd /var/log/packages
  PRGNAM_DB=$(ls $PRGNAM*)
  if [ -e "$PRGNAM_DB" ]; then
    PRGNAM_DB_NAME=$(ls $PRGNAM_DB | rev | cut -f4- -d- | rev)
    PRGNAM_DB_VERSION=$(ls $PRGNAM_DB | rev | cut -f3 -d- | rev)
    if [ "$PRGNAM" == "$PRGNAM_DB_NAME" ]; then
      if [ "$VERSION_INSTALL <= $PRGNAM_DB_VERSION" ]; then
	echo "Program [$PRGNAM-$VERSION_INSTALL] installed."
	exit 0
      fi
    fi
  fi
  cd $TOTAL_DIR
}

VIEW(){
  if [ "$VIEW_OK" != "" ] ; then
    export VIEW_OK="$VIEW_OK|$CLASS/$PRGNAM"
  else
    export VIEW_OK="$CLASS/$PRGNAM"
  fi

  if [ "$VIEW_DEP" == "" ] ; then
    VIEW_DEP=""
  fi

  echo "- [ $CLASSE/$PRGNAM ]"

  for i in $(grep -Ewv "$VIEW_OK" $PORTSDB/$CLASSE/$PRGNAM/$DEP) ; do
    if [ "$i" != "" ] ; then
      export VIEW_OK="$VIEW_OK $i"
      cd $DIRPORTS/$i
      export VIEW_DEP="$VIEW_DEP $(./$PORTSCRIPT view || ERROR)"
      cd $TOTAL_DIR
    fi
  done

  for i in $(grep -Ewv "$VIEW_OK" $PORTSDB/$CLASSE/$PRGNAM/$OPTIONAL_DEP) ; do
    if [ "$i" != "" ] ; then
      export VIEW_OK="$VIEW_OK $i"
      cd $DIRPORTS/$i
      export VIEW_DEP="$VIEW_DEP $(./$PORTSCRIPT view || ERROR)"
      cd $TOTAL_DIR
    fi
  done

  echo "$VIEW_DEP"
}

DOWNLOAD_SOURCE(){
  if [ "$ARCH" == "x86_64" ]; then
    if [ "$DOWNLOAD_x86_64" == "" ] || [ "$DOWNLOAD_x86_64" == "UNSUPPORTED" ] || [ "$DOWNLOAD_x86_64" == "UNTESTED" ];then
      LINK_DOWNLOAD=$DOWNLOAD
    else
      LINK_DOWNLOAD=$DOWNLOAD_x86_64
    fi
  else
    LINK_DOWNLOAD=$DOWNLOAD
  fi

  LINK_DOWNLOAD_FILE=$(echo $LINK_DOWNLOAD | rev | cut -d/ -f1 | rev)
  for i in $LINK_DOWNLOAD; do 
    wget -c $i
  done
}

INSTALL(){
  sh "$PORTSDB/$CLASSE/$PRGNAM/$SCRIPT_BEFORE_INSTALL"
  upgradepkg --install-new --reinstall /tmp/$PRGNAM-$VERSION_INSTALL*-*-*_PSl.$TGZ_TXZ || ERROR
  sh "$PORTSDB/$CLASSE/$PRGNAM/$SCRIPT_AFTER_INSTALL"
  LOG install
}

DELETEPKG(){
  rm -rfv /tmp/$PRGNAM-$VERSION_INSTALL-*-*.$TGZ_TXZ || ERROR
}

REMOVEPKG(){
  sh "$PORTSDB/$CLASSE/$PRGNAM/$SCRIPT_BEFORE_REMOVE"
  removepkg $PRGNAM-$VERSION_INSTALL || ERROR
  sh "$PORTSDB/$CLASSE/$PRGNAM/$SCRIPT_AFTER_REMOVE"
  LOG remove
}

# Edit
#DEP_SOLUTION(){
#  for i in $(cat $PORTSDB/$CLASSE/$PRGNAM/$DEP | awk '{print $1}') ; do
#    if [ $i != "" ] ; then
#      cd $DIRPORTS/$i
#      ./$PORTSCRIPT $1 || ERROR
#      cd $TOTAL_DIR
#    fi
#  done
#}
# New
DEP_SOLUTION(){
  for i in $REQUIRES) ; do
    if [ $i != "" ] ; then
      cd $DIRPORTS/*/$i
      ./$PORTSCRIPT $1 || ERROR
      cd $TOTAL_DIR
    fi
  done
}

OPT_DEP_SOLUTION(){
  for i in $(cat $PORTSDB/$CLASSE/$PRGNAM/$OPTIONAL_DEP | awk '{print $1}') ; do
    if [ $i != "" ] ; then
      cd $DIRPORTS/$i
      ./$PORTSCRIPT $1 || ERROR
      cd $TOTAL_DIR
    fi
  done
}

case $1 in
  -h|help|-help|--help)
    echo "
      ATTENTION! not recommend that you remove packages by this script because it is being tested, use the pkgtool to remove.

      Clean up the current directory
      ./$PORTSCRIPT clean

      Download SlackBuilds script -> Download program
      ./$PORTSCRIPT source

      Download SlackBuilds script -> Download program -> run SlackBuilds script
      ./$PORTSCRIPT make

      Run SlackBuilds script
      ./$PORTSCRIPT makepkg

      Install Package
      ./$PORTSCRIPT installpkg

      Delete the package
      ./$PORTSCRIPT deletepkg

      Remove the installed package
      ./$PORTSCRIPT removepkg

      Download SlackBuilds script -> Download program -> run SlackBuilds script -> Install the package
      ./$PORTSCRIPT all

      Resolve dependencies -> Download SlackBuilds script -> Download program
      ./$PORTSCRIPT dep-source

      Resolve dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script
      ./$PORTSCRIPT dep-make

      Resolve dependencies -> Run SlackBuilds script
      ./$PORTSCRIPT dep-makepkg

      Resolve dependencies -> Install Package
      ./$PORTSCRIPT dep-installpkg

      Resolve dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script -> Install the package
      ./$PORTSCRIPT dep-all

      Delete the package and the dependencies
      ./$PORTSCRIPT dep-deletepkg

      Remove the package installed and the dependencies
      ./$PORTSCRIPT dep-removepkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Download SlackBuilds script -> Download program
      ./$PORTSCRIPT opt-source

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script
      ./$PORTSCRIPT opt-make

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Run SlackBuilds script
      ./$PORTSCRIPT opt-makepkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Install Package
      ./$PORTSCRIPT opt-installpkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script -> Install the package
      ./$PORTSCRIPT opt-all

      Delete the package and the dependencies and optional dependencies
      ./$PORTSCRIPT opt-deletepkg

      Remove the package installed, dependencies and optional dependencies
      ./$PORTSCRIPT opt-removepkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Resolve optional dependencies -> Resolve optional dependencies of optional dependencies -> Download SlackBuilds script -> Download program
      ./$PORTSCRIPT opt-dep-source

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Resolve optional dependencies -> Resolve optional dependencies of optional dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script
      ./$PORTSCRIPT opt-dep-make

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Resolve optional dependencies -> Resolve optional dependencies of optional dependencies -> Run SlackBuilds script
      ./$PORTSCRIPT opt-dep-makepkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Resolve optional dependencies -> Resolve optional dependencies of optional dependencies -> Install Package
      ./$PORTSCRIPT opt-dep-installpkg

      Resolve dependencies -> Resolve dependencies of optional dependencies -> Resolve optional dependencies -> Resolve optional dependencies of optional dependencies -> Download SlackBuilds script -> Download program -> run SlackBuilds script -> Install the package
      ./$PORTSCRIPT opt-dep-all

      Delete the package and the dependencies and optional dependencies
      ./$PORTSCRIPT opt-dep-deletepkg

      Remove the package installed and the dependencies and optional dependencies
      ./$PORTSCRIPT opt-dep-removepkg
	  "
    exit 1
    ;;

  clean)
    for i in `ls | grep -v $PORTSCRIPT`; do  rm -rf $TOTAL_DIR/$i ; done
    exit 1
    ;;

  deletepkg)
    DELETEPKG || ERROR
    exit 1
    ;;

  removepkg)
    REMOVEPKG || ERROR
    exit 1
    ;;

  view)
    VIEW || ERROR
    ;;

  source)
    DOWNLOAD_SOURCE || ERROR
    exit 1
    ;;

  make) 
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    exit 1
    ;;

  makepkg)
    $TOTAL_DIR/$PRGNAM.SlackBuild  || ERROR
    exit 1
    ;;

  installpkg) 
    INSTALL || ERROR
    exit 1
    ;;

  all) 
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    INSTALL || ERROR
    echo "Package installed"
    exit 1
    ;;

#=================================================================
  dep-deletepkg)
    DEP_SOLUTION dep-deletepkg || ERROR
    CHECKS || ERROR
    DELETEPKG || ERROR
    exit 0
    ;;

  dep-removepkg)
    DEP_SOLUTION dep-removepkg || ERROR
    CHECKS || ERROR
    REMOVEPKG || ERROR
    exit 0
    ;;

  dep-source)
    DEP_SOLUTION dep-source || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    exit 0
    ;;

  dep-make)
    DEP_SOLUTION dep-make || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    exit 0
    ;;

  dep-makepkg)
    DEP_SOLUTION dep-makepkg || ERROR
    CHECKS || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild  || ERROR
    exit 0
    ;;

  dep-installpkg)
    DEP_SOLUTION dep-installpkg || ERROR
    CHECKS || ERROR
    INSTALL || ERROR
    exit 0
    ;;

  dep-all)
    DEP_SOLUTION dep-all || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    INSTALL || ERROR
    echo "Package installed"
    exit 0
    ;;

#=================================================================
  opt-deletepkg)
    DEP_SOLUTION dep-deletepkg || ERROR
    OPT_DEP_SOLUTION dep-deletepkg || ERROR
    DELETEPKG || ERROR
    exit 0
    ;;

  opt-removepkg)
    DEP_SOLUTION dep-removepkg || ERROR
    OPT_DEP_SOLUTION dep-removepkg || ERROR
    REMOVEPKG || ERROR
    exit 0
    ;;

  opt-source)
    DEP_SOLUTION dep-source || ERROR
    OPT_DEP_SOLUTION dep-source || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    exit 0
    ;;

  opt-make)
    DEP_SOLUTION dep-make || ERROR
    OPT_DEP_SOLUTION dep-make || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    exit 0
    ;;

  opt-makepkg)
    DEP_SOLUTION dep-makepkg || ERROR
    OPT_DEP_SOLUTION dep-makepkg || ERROR
    CHECKS || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild  || ERROR
    exit 0
    ;;

  opt-installpkg)
    DEP_SOLUTION dep-installpkg || ERROR
    OPT_DEP_SOLUTION dep-installpkg || ERROR
    CHECKS || ERROR
    INSTALL || ERROR
    exit 0
    ;;

  opt-all)
    DEP_SOLUTION dep-all || ERROR
    OPT_DEP_SOLUTION dep-all || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    INSTALL || ERROR
    echo "Package installed"
    exit 0
    ;;

#=================================================================
  opt-dep-deletepkg)
    DEP_SOLUTION dep-deletepkg || ERROR
    DEP_SOLUTION opt-dep-deletepkg || ERROR
    OPT_DEP_SOLUTION dep-deletepkg || ERROR
    OPT_DEP_SOLUTION opt-dep-deletepkg || ERROR
    DELETEPKG || ERROR
    exit 0
    ;;

  opt-dep-removepkg)
    DEP_SOLUTION dep-removepkg || ERROR
    DEP_SOLUTION opt-dep-removepkg || ERROR
    OPT_DEP_SOLUTION dep-removepkg || ERROR
    OPT_DEP_SOLUTION opt-dep-removepkg || ERROR
    REMOVEPKG || ERROR
    exit 0
    ;;

  opt-dep-source)
    DEP_SOLUTION dep-source || ERROR
    DEP_SOLUTION opt-dep-source || ERROR
    OPT_DEP_SOLUTION dep-source || ERROR
    OPT_DEP_SOLUTION opt-dep-source || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    exit 0
    ;;

  opt-dep-make)
    DEP_SOLUTION dep-make || ERROR
    DEP_SOLUTION opt-dep-make || ERROR
    OPT_DEP_SOLUTION dep-make || ERROR
    OPT_DEP_SOLUTION opt-dep-make || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    exit 0
    ;;

  opt-dep-makepkg)
    DEP_SOLUTION dep-makepkg || ERROR
    DEP_SOLUTION opt-dep-makepkg || ERROR
    OPT_DEP_SOLUTION dep-makepkg || ERROR
    OPT_DEP_SOLUTION opt-dep-makepkg || ERROR
    CHECKS || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild  || ERROR
    exit 0
    ;;

  opt-dep-installpkg)
    DEP_SOLUTION dep-installpkg || ERROR
    DEP_SOLUTION opt-dep-installpkg || ERROR
    OPT_DEP_SOLUTION dep-installpkg || ERROR
    OPT_DEP_SOLUTION opt-dep-installpkg || ERROR
    CHECKS || ERROR
    INSTALL || ERROR
    exit 0
    ;;

  opt-dep-all)
    DEP_SOLUTION dep-all || ERROR
    DEP_SOLUTION opt-dep-all || ERROR
    OPT_DEP_SOLUTION dep-all || ERROR
    OPT_DEP_SOLUTION opt-dep-all || ERROR
    CHECKS || ERROR
    DOWNLOAD_SOURCE || ERROR
    $TOTAL_DIR/$PRGNAM.SlackBuild || ERROR
    INSTALL || ERROR
    echo "Package installed"
    exit 0
    ;;
esac

exit 0
