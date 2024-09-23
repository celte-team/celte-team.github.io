# Building Celte

Start by cloning [celte-systems](https://github.com/celte-team/celte-system).

Celte is written in C++ using vcpkg to handle its external dependencies.
If you are working on linux, you can build the binaries using the provided docker file at the
root of the repository.

# How to build using CMake

The build system uses CMake and VCPKG. Make sure you have those two installed before proceeding. Additionally, make sure that the env variable VCPKG_ROOT is defined in your environment, and that it points to the install folder of VCPKG.


If you want to integrate Celte into a godot project and wish to setup the build system automatically, run the following command from the root of the repository:

```bash
./automations/setup_repository.sh path/to/gdproj
```
The argument of this command should point to the root folder of the godot project that you wish to use Celte with. It will make sure that, upon running the `make install` command, all Celte dependencies are copied to `path/to/gdproj/bin/deps` so that they can be exported alongside your game project.

If you wish to build Celte manually, make sure that:
- `VCPKG_ROOT` is defined
- `VCPKG_TARGET_TRIPLET` is defined to the value corresponding to your os (arm64-osx, linux-x64...)
- you call cmake with `-DCMAKE_PREFIX_PATH=path/to/gdproj`
- you do all this from a `build` folder (in source build is disabled)


Then run the following command in the terminal:
```
mkdir build && cd build && cmake --preset default .. -DCMAKE_PREFIX_PATH=path/to/gdproj
```
