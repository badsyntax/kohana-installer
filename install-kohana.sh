#!/bin/sh

# have submodules been added?
MODS=0

echo " "
echo "This script will install the current development version of Kohana from Github. To use the latest stable release, run \"git submodule foreach 'git checkout master'\" after installation."
echo " "
echo " > Continue installation? (Y/n): \c"
read install

if [[ $install == "N" ||  $install == "n" ]]; then
	# abort installation
	exit 0
fi

echo " > Install to? (Directory name): \c"
read dir

if [[ -n $dir ]]; then
	if [ ! -d $dir ]; then
		echo "   ~ Creating directory ... \c"

		# create directory
		mkdir $dir > /dev/null 2>&1
		if [[ $? == 0 ]]; then
			echo "done."
		else
			echo "failed."
			echo " ! Could not create requested directory."
			exit 1
		fi
	fi

	# use directory
	cd $dir
fi

if [[ ! -d ".git" ]]; then
	echo "   ~ Creating git repository ... \c"
	# create local repo
	git init \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi
fi

# ! This fails because git returns an error status when using the default Github branch.
# ! Some kind of work around will be required to handle the 3.0.x branch.

# echo "What branch do you want to use? (master): \c"
# read branch
# 
# if [[ $branch == "" ]]; then
# 	# default to using stable branch
# 	branch="master"
# elif [[ $branch != "master" && $branch != "3.0.x" && $branch != "3.1.x" ]]; then
# 	# invalid branch
# 	echo " ! Invalid branch $branch."
# 	exit 1
# fi

if [[ ! -d "system" ]]; then
	echo "   ~ Installing system module ... \c"
	# install core module
	git submodule add git://github.com/kohana/core.git system \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then
		echo "done."
		# new module added
		MODS=1
	else
		echo "failed."
	fi
fi

echo " > Do you want to install any modules? (Y/n): \c"
read install

if [[ $install == "" ||  $install == "Y" || $install == "y" ]]; then
	while [ 1 ]; do
		echo " > Module name? (Blank to stop): \c"
		read module

		if [ -z "$module" ]; then
			# stop asking for modules
			break
		fi

		echo "   ~ Installing $module ... \c"
		# install module
		git submodule add "git://github.com/kohana/$module.git" modules/$module \
			> /dev/null 2>&1
		# success?
		if [[ $? == 0 ]]; then
			echo "done."
			# new module added
			MODS=1
		else
			echo "failed."
		fi
	done
fi

if [[ $MODS == 1 ]]; then
	echo "   ~ Committing submodules ... \c"
	# initialize and commit modules
	git submodule init \
		> /dev/null 2>&1
	git commit -m 'Modules installed' \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi
fi

echo " > Create application structure? [Y/n] \c"
read install

if [[ $install == "" ||  $install == "Y" || $install == "y" ]]; then

	echo "   ~ Creating structure ... \c"

	# controllers and models
	mkdir -p application/classes/{controller,model}
	mkdir -p application/{config,views}

	# cache and logs must be writable
	mkdir -m 0777 -p application/{cache,logs}

	# ignore log and cache files
	echo '[^.]*' > application/logs/.gitignore
	echo '[^.]*' > application/cache/.gitignore

	# structure created
	echo "done."

	echo "   ~ Downloading index.php ... \c"
	# get index.php
	curl -o index.php \
		https://github.com/kohana/kohana/raw/master/index.php \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi

	echo "   ~ Downloading bootstrap.php ... \c"
	# get bootstrap.php
	curl -o application/bootstrap.php \
		https://github.com/kohana/kohana/raw/master/application/bootstrap.php \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi

	echo "   ~ Committing application structure ... \c"
	git add index.php application \
		> /dev/null 2>&1
	git commit -m "Basic application structure created" \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi
fi

echo " > Switch to stable release? (y/N): \c"
read install

if [[ $install == "Y" || $install == "y" ]]; then
	echo "   ~ Switching to stable versions of modules ... \c"
	git submodule foreach 'git checkout master' \
		> /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then echo "done."; else echo "failed."; fi
fi

# success!
echo " ! Kohana has been installed. Enjoy!"

# fin
exit 0
