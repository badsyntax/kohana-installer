#!/bin/sh

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
		echo "   ~ Creating directory: $dir ... \c"

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
	git init > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
fi

if [[ ! -d "system" ]]; then
	echo "   ~ Installing system module ... \c"
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
		git submodule add "$GITHUB/kohana/$module.git" "modules/$module" > /dev/null 2>&1
		# success?
		if [[ $? == 0 ]]; then
			[[ $MODS == 1 ]] || MODS=1 # new module installed
			echo "done."
		else
			echo "failed."
		fi
	done
fi

if [[ $MODS == 1 ]]; then
	while true; do
		echo " > What branch do you want to use? ($DEFAULT_BRANCH): \c"
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
			echo "   ~ Selecting $BRANCH for all submodules ... \c"
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

	echo "   ~ Committing submodules ... \c"
	# initialize and commit modules
	git submodule init > /dev/null 2>&1
	git commit -m 'Modules installed' > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
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
	curl --output index.php "$GITHUB/kohana/kohana/raw/$BRANCH/index.php" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo "   ~ Downloading bootstrap.php ... \c"
	# get bootstrap.php
	curl --output application/bootstrap.php "$GITHUB/kohana/kohana/raw/$BRANCH/application/bootstrap.php" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo "   ~ Downloading .htaccess ... \c"
	# get .htaccess
	curl --output .htaccess "$GITHUB/kohana/kohana/raw/$BRANCH/example.htaccess" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."

	echo "   ~ Committing application structure ... \c"
	git add .htaccess index.php application > /dev/null 2>&1
	git commit -m "Basic application structure created" > /dev/null 2>&1
	# success?
	[[ $? == 0 ]] && echo "done." || echo "failed."
fi

# success!
echo " = Kohana has been installed."

# fin
exit 0
