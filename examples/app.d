import std.stdio;
import std.string: toStringz, fromStringz;
import std.format: format;
import deimos.libzip.zip;

string get_manifest_content(zip_t* zip_obj) {
    if (zip_name_locate(zip_obj, "manifest.json".toStringz, ZIP_FL_ENC_GUESS)) {
        writeln("Manifest found in archive");
        auto manifest_file = zip_fopen(zip_obj, "manifest.json".toStringz, ZIP_FL_ENC_GUESS);
        scope(exit) zip_fclose(manifest_file);
        ubyte[] manifest_content;
        ubyte[1024] buf;
        long res;
        do {
            res = zip_fread(manifest_file, buf.ptr, 1024);
            manifest_content ~= buf[0..res];
        } while(res > 0);
        if (res < 0) {
            writeln("Error");
        }
        return cast(string)manifest_content;
    }
    return null;
}

void main(string[] args)
{
    writeln("Libzip version: %s".format(zip_libzip_version().fromStringz));

	writeln("Checking zip archive %s".format(args[1]));

    int error;
    auto zip_obj = zip_open(args[1].toStringz, ZIP_RDONLY, &error);
    scope(exit) zip_close(zip_obj);
    if (error) {
        writeln("Error code: %s".format(error));
        return;
    }
    string manifest = get_manifest_content(zip_obj);
    writeln("Manifest content:\n\n%s".format(manifest));
}
