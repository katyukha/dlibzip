import std.stdio;
import std.string: toStringz, fromStringz, strip;
import std.format: format;
import std.algorithm.searching: endsWith;
import std.path;
import std.file;
import deimos.zip;


int main(string[] args)
{
    writeln("Libzip version: %s".format(zip_libzip_version().fromStringz));

    if (args.length < 3) {
        writeln("Usage: unarchive archive.zip dest");
        return 1;
    }
    auto source = std.path.buildNormalizedPath(
        std.path.absolutePath(args[1].expandTilde));
    auto dest = std.path.buildNormalizedPath(
        std.path.absolutePath(args[2].expandTilde));

    if (dest.exists) {
        writeln("Destination already exists");
        return 2;
    }

	writeln("Unarchiving zip archive %s to %s".format(source, dest));

    int error;
    auto zip_obj = zip_open(args[1].toStringz, ZIP_RDONLY, &error);
    scope(exit) zip_close(zip_obj);
    if (error) {
        // TODO: Provide better example of error handling.
        writeln("Error code: %s".format(error));
        return 3;
    }

    // Create destination directory
    mkdirRecurse(dest);

    auto num_entries = zip_get_num_entries(zip_obj, 0);
    for(ulong i=0; i < num_entries; ++i) {
        zip_stat_t stat;
        zip_stat_index(zip_obj, i, 0, &stat);
        string entry_name = cast(string)fromStringz(stat.name);

        // If by ocasion name is started with '/', then remove leading '/',
        // before futher processing.
        entry_name = entry_name.strip("/", "");

        auto dest_path = buildNormalizedPath(dest, entry_name);

        if (entry_name.endsWith("/")) {
            // It it is directory, then we have to create one in destination.
            writeln("Creation directory: %s".format(entry_name));
            mkdirRecurse(dest_path);
        } else {
            // If it is file, then we have to extract file.
            writeln("Extracting file: %s".format(entry_name));

            auto out_file = std.stdio.File(dest_path, "wb");
            scope(exit) out_file.close();

            auto afile = zip_fopen_index(zip_obj, i, ZIP_FL_ENC_GUESS);
            scope(exit) zip_fclose(afile);

            ulong size_written = 0;
            while (size_written != stat.size) {
                byte[1024] buf;
                auto size_read = zip_fread(afile, &buf, 1024);
                if (size_read > 0) {
                    out_file.rawWrite(buf);
                    size_written += size_read;
                } else {
                    writeln("Cannot read file %s. Read: %s/%s".format(
                        entry_name, size_written, stat.size));
                    return 4;
                }
            }
        }
    }

    writeln("Unarchive completed!");
    return 0;
}
