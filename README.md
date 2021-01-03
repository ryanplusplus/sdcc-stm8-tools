# sdcc-stm8-tools
Toolchain and other tools required for build, debug, and upload using `sdcc` for STM8.

## Setup
- Copy `tools/Linux/udev/70-st-link.rules` to `/etc/udev/rules.d/` and run `udevadm control --reload-rules`.
- Create a makefile from `template.mk`.
- Configure debug configuration using the sample provided in `.vscode/launch.json` and `.vscode/tasks.json`

## Use
### Compile
```shell
make -f <target>.mk
```

### Clean
```shell
make -f <target>.mk clean
```

### Erase via SWIM
```shell
make -f <target>.mk erase
```

### Flash via SWIM
```shell
make -f <target>.mk upload
```

### Debug via GDB TUI
```shell
make -f <target>.mk debug
```

### Open documentation
```shell
make -f <target>.mk datasheet
```

```shell
make -f <target>.mk hardware_manual
```
