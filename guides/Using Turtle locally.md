# Using Turtle locally

This document will guide you through building standalone app from Managed Expo project using local Turtle builder.

## Prepare `turtle-cli`

1. Ensure you've got `turtle-cli` installed locally

`npm i -g turtle-cli`

2. `turtle` has some references for `shellTarballs` - these are located under `<place where turtle is installed>/turtle-cli/shellTarballs`

```
cd `which turtle`/../../shellTarballs
```

3. `turtle` downloads `shellTarballs` and places them under `~/.turtle/workingdir` directory (`/android` or `/ios` respectively).

## Replacing Android/iOS shellTarball used during build process

You can replace specific `shellTarball` by replacing existing one with yours:

> You can take a look at `/.circleci/config.yml` file and search for `shell_app_ios_build` or `shell_app_android_build` commands. There are responsible for preparing new `shellTarballs` that are used by `turtle` service to build standalone Expo apps from Managed Expo projects.

## Replacing Android shellTarball

> Remember: if you've modified any `expoview` or `package/*` that has it's native code published from `expoview-npm-package` then you'll have to rebuild them!
> To do so [go here](./Updating%20Expokit%20Package%20For%20Ejected%20Android%20Projects%20and%20Turtle.md).
> command: `et android-build-packages --sdkVersion XX.X.X`

1. Run `./buildAndroidTarballLocally.sh`. That would create freshly packed `shellTarball` under `artifacts` directory.
> You cannot prevent script from archiving shellTarball, because it has to move actual files and not symlinks.
2. Remove `shellTarball` from `~/.turtle/workingdir/android/<sdkXX>`.
3. Recreate removed directory & extract new `shellTarball` into that directory:
```
tar -zxvf ./artifacts/android-shell-builder.tar.gz --directory ~/.turtle/workingdir/android/<sdkXX>
```
4. `turtle-cli` checks for correctness of `shellTarball` by looking for `.ready` file containing URL that points to `shellTarball` available online.
We need to fool `turtle-cli` by creating such file that would contain correct URL address.
```
cat `<place where turtle is installed>/turtle-cli/shellTarballs/android/sdkXX > ~/.turtle/workingdir/android/<sdkXX>/.ready
```
5. `yarn` in extracted directory.

## Replacing iOS shellTarball

1. Create new `shellTarball` by following commands from `/.circleci/config.yml` describing `shell_app_ios_build` task.
2. Replace current `shellTarball` with freshly built one (see Android section).
