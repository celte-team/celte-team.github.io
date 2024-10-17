
# Godot: how to compile godot extension using makefile

## Client extension

The rules for compiling the client extension are defined in the `Makefile` located in the `godot` folder of the Celte repository.

### Rule 'client'
This rule is used to compile the client extension with the rule `client-systems` and use it for export the project. The client project is exported in the `gdproj/export` folder. We can set the `Target_client` variable to the platform we want to export the project to.

### Rule 'client-systems'
This rule compiles the systems of the client using `scons`. We start by setting the path of the gdextension library into the extension_list of godot. Then we put the gdextension library into the `gdproj/bin` folder. Finally, we compile the systems of the client using `scons`.


## Server extension

The rules for compiling the server extension are defined in the `Makefile` located in the `godot` folder of the Celte repository.

### Rule 'server'
This rule is used to compile the server extension with the rule `server-systems` and use it for export the project. The server project is exported in the `gdproj/export` folder. We can set the `Target_server` variable to the platform we want to export the project to.

### Rule 'server-systems'

This rule compiles the systems of the server using `scons`. We start by setting the path of the gdextension library into the extension_list of godot. Then we put the gdextension library into the `gdproj/bin` folder. Finally, we compile the systems of the server using `scons`.

## Use Godot project

To use the godot project, you need to open the project located in the `gdproj/export` folder. You can then run the project and see the result of the systems you have compiled.
