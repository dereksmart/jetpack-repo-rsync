#!/usr/bin/env bash

# Print help and exit.
function usage {
	cat <<-EOH
		usage: $0 [-p <slug>][-w]

		rsync changes to plugins

		Pass \`-p <plugin_slug>\` to target a specific plugin in projects/plugins/ (defaults to jetpack).
		Pass \`-w\` to "watch" and auto-push changes when made (requires fswatch). Works best if using keypair auth.
	EOH
	exit 1
}

PLUGIN="jetpack"
WATCH=
while getopts ":p:hw" opt; do
	case ${opt} in
		p)
			PLUGIN=$OPTARG
			;;
		w)
			WATCH=true
			;;
		h)
  		usage
  		;;
		*)
		  echo "Command not supported."
			usage;
			exit 1
			;;
	esac
done
shift "$(($OPTIND - 1))"

# Point to your local Jetpack checkout
JETPACK_REPO_PATH=""
# Point to the source /plugins directory
DEST_PLUGINS_PATH=""

if [[ -z $JETPACK_REPO_PATH ]]; then
  echo "No source found. Please update JETPACK_REPO_PATH."
  exit 1
fi

if [[ -z $DEST_PLUGINS_PATH ]]; then
  echo "No destination found. Please update DEST_PLUGINS_PATH."
  exit 1
fi

SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )
SOURCE="$JETPACK_REPO_PATH/projects/plugins/$PLUGIN"
FILTER_FILES="$SCRIPT_DIR/filter-files.txt"

function rsyncpush() {
	rsync -azLKv --delete --delete-after \
		--filter="merge $FILTER_FILES" \
		--rsync-path="mkdir -p $DEST_PLUGINS_PATH/$PLUGIN && rsync" \
		"$SOURCE" \
		"$DEST_PLUGINS_PATH"
}

function rsyncwatch() {
	fswatch -or --filter-from="$FILTER_FILES" "$SOURCE" | \
	while read -r changes; do
		echo "$changes Changes detected. Pushing..."
		rsyncpush;
		echo "Done!"
		echo "Watching..."
	done
}

if [[ -n $WATCH ]]; then
	echo "Watching $PLUGIN for things to auto-push..."
	rsyncwatch
else
  rsyncpush
fi
