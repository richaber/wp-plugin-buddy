# wp-plugin-buddy

Deploy plugin updates to WordPress.org's plugin SVN using a [Buddy Local Shell action](https://buddy.works/actions/terminal).

## Warning

Use at your own risk.

This is experimental, untested (so far), and _possibly completely broken_. I am not well versed in [Buddy](https://buddy.works/), and this is a first attempt at deploying a plugin to [WPORG's SVN release repository](https://developer.wordpress.org/plugins/wordpress-org/how-to-use-subversion/) via Buddy. Additionally, my SVN skills are very rusty.

This is based on Erick Hitter's GitLab CI deploy script [ethitter/wp-org-plugin-deploy](https://github.com/ethitter/wp-org-plugin-deploy) [version 2019051201](https://github.com/ethitter/wp-org-plugin-deploy/blob/master/scripts/deploy.sh#L19).

## Environment Variables

The following [environment variables](https://buddy.works/docs/pipelines/environment-variables) must be configured in Buddy:

* `BUDDY_PROJECT_DIR` -- Full path of directory where Buddy checks out Git repo
* `GIT_CONFIG_USER_EMAIL` -- Your Git config email address
* `GIT_CONFIG_USER_NAME` -- Your Git config user name
* `SVN_BUILDS_DIR` -- Full path of directory where SVN work is performed
* `WP_ORG_SLUG` -- Your plugin's WPORG slug
* `WP_ORG_USERNAME` -- Your WPORG username
* `WP_ORG_PASSWORD` -- Your WPORG password (Enable [Encryption](https://buddy.works/docs/pipelines/handling-secrets#environment-variables-encryption) on this)
* `WP_ORG_ASSETS_DIR` -- Git Directory where your [plugin assets](https://developer.wordpress.org/plugins/wordpress-org/plugin-assets/) are held
