
<h1> Archbd Installer Script </h1>
<body>

<p> Arch Linux is an independent distro for advance linux users. Its main challange is it's installation process. Command line is its main way to install this distro as it gives complete freedom to the user to choose which package they need to install. So, noob users may find it very difficult to install. I created this archlinux installer for learning bash scripting. I'm still noob and ofcourse there are advance installer out there. I tried to make the script easier as far as I could so that anyone can understand whats in there. I suggest to try this on virtualbox first if you are first in arch linux. HAPPY ARCHING! :) </p>

<h1> Prerequisities</h1>
<p>
<li>1. Active internet connection</li>
<li>2. Must be logged in as root</li>
</p>

<h1>How to get it</h1>
<p>
You can use this link to download the installer using wget while in root terminal:<br>
wget https://raw.githubusercontent.com/Neil-seu/archbd-installer-script/master/archbd.sh

<p>
<p>
Short form:<br> wget -O archbd.sh http://tiny.cc/3likmy
</p>
You can always find my project at:<br>
https://github.com/Neil-seu/archbd-installer-script
</p>

<h1>How to use it</h1>
<p>
After downloading just run<br>
<b>sh archbd.sh</b>

then follow the instruction :)
</p>

<h1> Features </h1>
<p>
I tried to make the script easier as far as I could. I tried to make such way that user almost have nothing to do anything manually. This installer is initially supported only bios-mbr scheme. so in partition editor i used cfdisk. And nowadays, swap is almost not necessary so that I intensionally skip the swap option to make the script lighter. In the base installation, I tried to add all necessary system libraries and packages so that user have nothing to worry about to install those later. In software, I initially add few softwares and xfce, gnome, deepin, lxqt, lxde, mate, cinnamon, kde-plasma as desktop environment. :)
</p>

<h1> Contact with me </h1>
<p>If you have any query or if you want to contribute this project, please feel free to contact with me through 
<b> tariqulislamseu@gmail.com </b>
</p>




<p>
<b> Special thanks to Muhammad Ariful Islaam and Dreamless Raqib vai as they helped me a lot to fix many bugs and gave many advices and also thanks to Tobias Muller as he provided some important packages and specially helped me to test the whole script to find bugs.</b>
</p>

</body>
