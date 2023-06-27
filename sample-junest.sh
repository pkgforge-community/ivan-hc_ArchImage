#!/bin/sh
# NAME OF THE APP, REPLACE SAMPLE OR EDIT THE PARTS INCLUDING "$APP" MANUALLY, IF NEEDED
# FOR EXAMPLE THE PACKAGE "obs-studio" CAN BE STARTED WITH THE BINARY IS "obs"
APP=SAMPLE

# THIS WILL DO ALL WORK INTO THE CURRENT DIRECTORY
HOME="$(dirname "$(readlink -f $0)")" 

# DOWNLOAD AND INSTALL JUNEST (DON'T TOUCH THIS)
git clone https://github.com/fsquillace/junest.git ~/.local/share/junest
./.local/share/junest/bin/junest setup

# CUSTOM MIRRORLIST, THIS SHOULD SPEEDUP THE INSTALLATION OF THE PACKAGES IN PACMAN (COMMENT EVERYTHING TO USE THE DEFAULT MIRROR)
rm -R ./.junest/etc/pacman.d/mirrorlist
COUNTRY=$(curl -i ipinfo.io | grep country | cut -c 15- | cut -c -2)
wget -q https://archlinux.org/mirrorlist/?country="$(echo $COUNTRY)" -O - | sed 's/#Server/Server/g' >> ./.junest/etc/pacman.d/mirrorlist

# INSTALL THE APP WITH ALL THE DEPENDENCES NEEDED, THE WAY YOU DO WITH PACMAN (YOU CAN ALSO REPLACE "$APP", SEE LINE 4)
./.local/share/junest/bin/junest -- sudo pacman -Syy
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S $APP

# SET THE LOCALE (DON'T TOUCH THIS)
sed "s/#$(echo $LANG)/$(echo $LANG)/g" ./.junest/etc/locale.gen >> ./locale.gen
rm ./.junest/etc/locale.gen
mv ./locale.gen ./.junest/etc/locale.gen
rm ./.junest/etc/locale.conf
echo "LANG=$LANG" >> ./.junest/etc/locale.conf
sed -i 's/LANG=${LANG:-C}/LANG=$LANG/g' ./.junest/etc/profile.d/locale.sh
./.local/share/junest/bin/junest -- sudo pacman --noconfirm -S glibc gzip
./.local/share/junest/bin/junest -- sudo locale-gen

# VERSION NAME, BY DEFAULT THIS POINTS TO THE NUMBER, CHANGE 'REPO' TO 'core', 'extra'...
# OR CHANGE THE WHOLE URL TO ANOTHER SOURCE, FOR EXAMPLE IF THE PACKAGE IS ON AUR OR CHAOTIC-AUR
VERSION=$(wget -q https://archlinux.org/packages/REPO/x86_64/$APP/ -O - | grep $APP | head -1 | grep -o -P '(?<='$APP' ).*(?=</)' | tr -d " (x86_64)")

# CREATE THE APPDIR (DON'T TOUCH THIS)...
wget -q https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-x86_64.AppImage -O appimagetool
chmod a+x appimagetool
mkdir $APP.AppDir
cp -r ./.local ./$APP.AppDir/
cp -r ./.junest ./$APP.AppDir/

# ...ADD THE ICON AND THE DESKTOP FILE AT THE ROOT OF THE APPDIR (IF PATHS AND APPS ARE DIFFERENT YOU CAN CHANGE EVERYTHING)...
cp ./$APP.AppDir/.junest/usr/share/icons/hicolor/scalable/apps/*$APP* ./$APP.AppDir/
cp ./$APP.AppDir/.junest/usr/share/applications/*$APP* ./$APP.AppDir/

# ...AND FINALLY CREATE THE APPRUN, IE THE MAIN SCRIPT TO RUN THE APPIMAGE!
# THE APPROACH "echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n" ALLOWS YOU TO RUN THE APP IN A JUNEST SECTION DIRECTLY
# EDIT THE FOLLOWING LINES IF YOU THINK SOME ENVIRONMENT VARIABLES ARE MISSING
cat >> ./$APP.AppDir/AppRun << 'EOF'
#!/bin/sh
APP=SAMPLE
HERE="$(dirname "$(readlink -f $0)")"
export UNION_PRELOAD=$HERE
export JUNEST_HOME=$HERE/.junest
export PATH=$HERE/.local/share/junest/bin/:$PATH
echo "$APP $@" | $HERE/.local/share/junest/bin/junest -n
EOF
chmod a+x ./$APP.AppDir/AppRun

# REMOVE SOME BLOATWARES (BY DEFAULT I REMOVE /var, YOU CAN ADD WHATEVER YOU WANT IN THIS LIST, THE MORE IMPORTANT THING IS THAT THE APP WORKS) 
rm -R -f ./$APP.AppDir/.junest/var

# REMOVE THE INBUILT HOME AND SYMLINK THE ONE FROM THE HOST (EXPERIMENTAL, NEEDED FOR PORTABILITY)
#rm -R -f ./$APP.AppDir/.junest/home
#ln -s /home ./$APP.AppDir/.junest/home

# OPTIONS SPECIFIC FOR "AM" AND APPMAN (see https://github.com/ivan-hc/AM-Application-Manager)
mkdir -p ./$APP.AppDir/.junest/opt/$APP/$APP.home
mkdir -p ./$APP.AppDir/.junest/home/$(who | awk '{print $1}')/$(cat /home/$(who | awk '{print $1}')/.config/appman/appman-config)/$APP/$APP.home

# CREATE THE APPIMAGE
ARCH=x86_64 ./appimagetool -n ./$APP.AppDir
mv ./*AppImage ./$APP-$VERSION-x86_64.AppImage
