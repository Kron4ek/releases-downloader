## Releases Downloader

This is a small and simple program that allows to download releases from GitHub repositories. It supports a graphical user interface, as well as command-line interface. Currently available only for Linux.

## Usage
#### Graphical version
The graphical version is very minimal and simple. You just run the program, enter a github repository URL (or owner/reponame) and push the button, it will show you all available releases and assets.

#### Command-line (cli) version

The command-line (cli) version is very simple as well. You need to specify a GitHub repository URL (or owner/reponame), release number and asset number. Specifying just a repository URL (or owner/reponame) will show all available releases and assets. For example:

```
$ ./releases-downloader-cli_1.0_x64_Linux HansKristian-Work/vkd3d-proton
Available releases and assets:

1. Version 2.4
    1. vkd3d-proton-2.4.tar.zst
2. Version 2.3.1
    1. vkd3d-proton-2.3.1.tar.zst
3. Version 2.3
    1. vkd3d-proton-2.3.tar.zst
...
```

For example, to show a direct download link of the first asset attached to the first release, use:

```
$ ./releases-downloader-cli_1.0_x64_Linux HansKristian-Work/vkd3d-proton 1 1
https://github.com/HansKristian-Work/vkd3d-proton/releases/download/v2.4/vkd3d-proton-2.4.tar.zst
```

You can use this link with other programs (for example, with wget).

And if you want the program to download it instead of just showing the link, add `download` as the last argument.

```
./releases-downloader-cli_1.0_x64_Linux HansKristian-Work/vkd3d-proton 1 1 download
Download completed successfully.
```

## Screenshots

![releases window](https://i.imgur.com/fINJazQ.png)
![main window](https://i.imgur.com/W2Hiqh6.png)
