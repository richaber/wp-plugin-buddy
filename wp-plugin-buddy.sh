#!/usr/bin/env bash

# Based on ethitter/wp-org-plugin-deploy by Erick Hitter

set -eo

# Common cleanup actions.
function cleanup() {
	echo "ℹ︎ Cleaning up..."

	rm -rf "$SVN_DIR"
	rm -rf "$TMP_DIR"
}

# Provide a basic version identifier.
echo "ℹ︎ WP-PLUGIN-BUDDY VERSION: 20191226"

# Ensure environment variables are set.
# https://buddy.works/docs/pipelines/environment-variables
if [[ -z "$WP_ORG_USERNAME" ]]; then
	echo "𝘅︎ WordPress.org username not set" 1>&2
	exit 1
fi

if [[ -z "$WP_ORG_PASSWORD" ]]; then
	echo "𝘅︎ WordPress.org password not set" 1>&2
	exit 1
fi

if [[ -z "$WP_ORG_SLUG" ]]; then
	echo "𝘅︎ Plugin's SVN slug is not set" 1>&2
	exit 1
fi

# BUDDY_EXECUTION_TAG should match our tagged release version.
# https://buddy.works/blog/introducing-tag-push#buddy-params
if [[ -z "$BUDDY_EXECUTION_TAG" ]]; then
	echo "𝘅︎ Plugin's version is not set" 1>&2
	exit 1
fi

# Directory name, relative to repo root, where screenshots and other static assets are held.
if [[ -z "$WP_ORG_ASSETS_DIR" ]]; then
	WP_ORG_ASSETS_DIR=".wordpress-org"
fi

# Create empty static-assets directory if needed, triggering
# removal of any stray assets in svn.
if [[ ! -d "${BUDDY_PROJECT_DIR}/${WP_ORG_ASSETS_DIR}/" ]]; then
	mkdir -p "${BUDDY_PROJECT_DIR}/${WP_ORG_ASSETS_DIR}/"
fi

echo "ℹ︎ WP_ORG_SLUG: ${WP_ORG_SLUG}"
echo "ℹ︎ BUDDY_EXECUTION_TAG: ${BUDDY_EXECUTION_TAG}"
echo "ℹ︎ WP_ORG_ASSETS_DIR: ${WP_ORG_ASSETS_DIR}"

TIMESTAMP=$(date +"%s")

SVN_URL="https://plugins.svn.wordpress.org/${WP_ORG_SLUG}/"

SVN_DIR="${SVN_BUILDS_DIR}/svn/${WP_ORG_SLUG}-${TIMESTAMP}"

SVN_TAG_DIR="${SVN_DIR}/tags/${BUDDY_EXECUTION_TAG}"

TMP_DIR="${SVN_BUILDS_DIR}/git-archive/${WP_ORG_SLUG}-${TIMESTAMP}"

# Limit checkouts for efficiency
echo "➤ Checking out dotorg repository..."
svn checkout --depth immediates "$SVN_URL" "$SVN_DIR"
cd "$SVN_DIR"
svn update --set-depth infinity assets
svn update --set-depth infinity trunk
svn update --set-depth infinity "$SVN_TAG_DIR"

# Ensure we are in the $BUDDY_PROJECT_DIR directory, just in case
echo "➤ Copying files..."
cd "$BUDDY_PROJECT_DIR"

git config --global user.email "${GIT_CONFIG_USER_EMAIL}"
git config --global user.name "${GIT_CONFIG_USER_NAME}"

# If there's no .gitattributes file, write a default one into place
if [[ ! -e "${BUDDY_PROJECT_DIR}/.gitattributes" ]]; then
	cat > "${BUDDY_PROJECT_DIR}/.gitattributes" <<-EOL
	/${WP_ORG_ASSETS_DIR} export-ignore
	/.gitattributes export-ignore
	/.gitignore export-ignore
	EOL

	# The .gitattributes file has to be committed to be used
	# Just don't push it to the origin repo :)
	git add .gitattributes && git commit -m "Add .gitattributes file"
fi

# This will exclude everything in the .gitattributes file with the export-ignore flag
mkdir -p "$TMP_DIR"
git archive HEAD | tar x --directory="$TMP_DIR"

cd "$SVN_DIR"

# Copy from clean copy to /trunk
# The --delete flag will delete anything in destination that no longer exists in source
rsync -r "$TMP_DIR/" trunk/ --delete

# Copy dotorg assets to /assets
rsync -r "${BUDDY_PROJECT_DIR}/${WP_ORG_ASSETS_DIR}/" assets/ --delete

# Add everything and commit to SVN
# The force flag ensures we recurse into subdirectories even if they are already added
# Suppress stdout in favor of svn status later for readability
echo "➤ Preparing files..."
svn add . --force > /dev/null

# SVN delete all deleted files
# Also suppress stdout here
svn status | grep '^\!' | sed 's/! *//' | xargs -I% svn rm % > /dev/null

# If tag already exists, remove and update from trunk.
# Generally, this applies when bumping WP version compatibility.
# svn doesn't have a proper rename function, prompting the remove/copy dance.
if [[ -d "$SVN_TAG_DIR" ]]; then
	echo "➤ Removing existing tag before update..."
	svn rm "$SVN_TAG_DIR"
fi

# Copy new/updated tag to maintain svn history.
if [[ ! -d "$SVN_TAG_DIR" ]]; then
	echo "➤ Copying tag..."
	svn cp "trunk" "$SVN_TAG_DIR"
fi

svn status

echo "➤ Committing files..."
svn commit -m "Update to version ${BUDDY_EXECUTION_TAG} from Buddy (${BUDDY_PIPELINE_URL}; ${BUDDY_EXECUTION_URL})" --no-auth-cache --non-interactive  --username "$WP_ORG_USERNAME" --password "$WP_ORG_PASSWORD"

cleanup

echo "✓ Plugin deployed!"
