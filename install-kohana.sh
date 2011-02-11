#!/bin/bash

# have submodules been added?
MODS=0

# Github base URL
GITHUB="https://github.com"

# Default branch
DEFAULT_BRANCH="3.0/master"

echo " "
echo "Kohana PHP Framework Installer"
echo "http://kohanaframework.org/"
echo " "
echo "This script will create a Git repository and install Kohana into it."
echo "You will be able to select the directory and branch you want to install."
echo " "
echo -n " > Continue installation? (Y/n): "
read install

if [[ $install == "N" ||  $install == "n" ]]; then
	# abort installation
	exit 0
fi

echo -n " > Install to? (Directory name): "
read dir

if [[ -n $dir ]]; then
	if [ ! -d $dir ]; then
		echo -n "   ~ Creating directory: $dir ... "

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
	echo -n "   ~ Creating git repository ... "
	# create local repo
	git init > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
fi

if [[ ! -d "system" ]]; then
	echo -n "   ~ Installing system module ... "
	# install core module
	git submodule add "$GITHUB/kohana/core.git" system > /dev/null 2>&1
	# success?
	if [[ $? == 0 ]]; then
		[[ $MODS == 1 ]] || MODS=1 # new module installed
		echo "done."
	else
		echo "failed."
	fi
fi

echo -n " > Do you want to install any modules? (Y/n): "
read install

if [[ $install == "" ||  $install == "Y" || $install == "y" ]]; then
	while [ 1 ]; do
		echo -n " > Module name? (Blank to stop): "
		read module

		if [ -z "$module" ]; then
			# stop asking for modules
			break
		fi

		echo -n "   ~ Installing $module ... "
		# install module
		git submodule add "$GITHUB/kohana/$module.git" "modules/$module" > /dev/null 2>&1
		# success?
		if [[ $? == 0 ]]; then
			[[ $MODS == 1 ]] || MODS=1 # new module installed
			echo "done."
		else
			if [ -d "modules/$name" ]; then
				# git will create this dir even if repo doesn't exist
				rm -r "modules/$name" > /dev/null 2>&1
			fi
			echo "failed."
		fi
	done
fi

if [[ $MODS == 1 ]]; then
	while true; do
		echo -n " > What branch do you want to use? ($DEFAULT_BRANCH): "
		read BRANCH

		if [[ $BRANCH == "" ]]; then
			# default to using stable branch
			BRANCH="$DEFAULT_BRANCH"
		fi

		# Check if the branch exists
		status=$(curl --silent --head --write-out "%{http_code}" $GITHUB/kohana/kohana/raw/$BRANCH/index.php |tail -n 1)

		if [[ $status != "200" ]]; then
			echo "   ! Invalid branch $BRANCH."
		else
			echo -n "   ~ Selecting $BRANCH for all submodules ... "
			# Update submodule branches
			git submodule foreach "git fetch && git checkout $BRANCH > /dev/null 2>&1" > /dev/null 2>&1
			# success?
			if [[ $? == 0 ]]; then
				[[ $MODS == 1 ]] || MODS=1 # new module installed
				echo "done."
			else
				echo "failed."
			fi
			# Selected a valid branch
			break
		fi
	done

	echo -n "   ~ Committing submodules ... "
	# initialize and commit modules
	git submodule init > /dev/null 2>&1
	git commit -m 'Modules installed' > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
fi

echo -n " > Create application structure? [Y/n] "
read install

if [[ $install == "" ||  $install == "Y" || $install == "y" ]]; then

	echo -n "   ~ Creating structure ... "

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

	echo -n "   ~ Downloading index.php ... "
	# get index.php
	curl --output index.php "$GITHUB/kohana/kohana/raw/$BRANCH/index.php" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo -n "   ~ Downloading bootstrap.php ... "
	# get bootstrap.php
	curl --output application/bootstrap.php "$GITHUB/kohana/kohana/raw/$BRANCH/application/bootstrap.php" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo -n "   ~ Downloading .htaccess ... "
	# get .htaccess
	curl --output .htaccess "$GITHUB/kohana/kohana/raw/$BRANCH/example.htaccess" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo -n "   ~ Committing application structure ... "
	git add .htaccess index.php application > /dev/null 2>&1
	git commit -m "Basic application structure created" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
fi

# success!
echo " = Kohana has been installed."

# fin
exit 0
