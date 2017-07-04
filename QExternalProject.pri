EP_BASE = $$OUT_PWD
EP_ENDL = "; \\$$escape_expand(\n\t)"

# Wraps the specified string with the color codes of light blue. (Works only under Unix-like
# systems.)
#
# param 1 A string to emphasize.
# return The emphasized string.
defineReplace(EP_Emphasize) {
    text = $$1
    unix {
        text = "\\033[1;34m$${text}\\033[0m"
    }
    return($$text)
}

# Generates a command script for creating directories of the specified target.
#
# param 1 The name of the custom target.
# return The command script for creating directories of the specified target.
defineReplace(EP_InitStep) {
    NAME = $$1

    # Check the preconditions for script generating.
    isEmpty(NAME) {
        error("Usage: EP_InitStep(<name>)")
    }

    # Generate command script for the appropriate platform.
    unix {
        BUILD_DIR = "$$EP_BASE/Build/$$NAME"
        INSTALL_DIR = "$$EP_BASE/Install/$$NAME"
        SOURCE_DIR = "$$EP_BASE/Source/$$NAME"
        STAMP_DIR = "$$EP_BASE/Stamp/$$NAME"

        # Create guard command for skipping this step if directories exist.
        command = "if [ -d $$SOURCE_DIR ] && [ -d $$BUILD_DIR ] && [ -d $$STAMP_DIR ] && \
            [ -d $$INSTALL_DIR ]; then exit 0; fi" $$EP_ENDL

        # Create commands for printing the step message.
        STEP = $$EP_Emphasize("Creating directories for \'$$NAME\'")
        command += "echo \"$$STEP\"" $$EP_ENDL

        # Create commands for creating directories.
        command += "mkdir -p $$BUILD_DIR" $$EP_ENDL
        command += "mkdir -p $$INSTALL_DIR" $$EP_ENDL
        command += "mkdir -p $$SOURCE_DIR" $$EP_ENDL
        command += "mkdir -p $$STAMP_DIR" $$EP_ENDL

        # Create commands for clearing the content of previously existed directories.
        command += "rm -rf $$BUILD_DIR/*" $$EP_ENDL
        command += "rm -rf $$INSTALL_DIR/*" $$EP_ENDL
        command += "rm -rf $$SOURCE_DIR/*" $$EP_ENDL
        command += "rm -rf $$STAMP_DIR/*"
    }
    else:win32 {
        error("Microsoft Windows platform is not supported yet.")
    }
    else {
        error("Unknown platform.")
    }

    # Return the generated command script.
    return($$command)
}

# Generates a command script for downloading and extracting the specified source archive.
#
# param 1 The name of the custom target.
# param 2 The URL of the source archive.
# param 3 The number of leading components to strip from file names on extraction.
# return The command script for downloading and extracting the specified source archive.
defineReplace(EP_DownloadStep) {
    NAME = $$1
    URL = $$2

    # Check the preconditions for script generating.
    isEmpty(NAME) || isEmpty(URL) {
        error("Usage: EP_DownloadStep(<name>, <URL>, [<strip>])")
    }

    # Generate command script for the appropriate platform.
    unix {
        BUILD_DIR = "$$EP_BASE/Build/$$NAME"
        SOURCE_DIR = "$$EP_BASE/Source/$$NAME"
        STAMP_FILE = "$$EP_BASE/Stamp/$$NAME/$${NAME}-download"

        # Create guard command for skipping this step if the sources are already downloaded.
        command = "if [ -f $$STAMP_FILE ]; then exit 0; fi" $$EP_ENDL

        # Create commands for printing the step message and the messages of download sub-step.
        STEP = $$EP_Emphasize("Performing download step (download and extract) for \'$$NAME\'")
        command += "echo \"$$STEP\"" $$EP_ENDL

        command += "echo \"-- downloading...\"" $$EP_ENDL
        command += "echo \"    src=\'$$URL\'\"" $$EP_ENDL
        command += "echo \"    dst=\'$$SOURCE_DIR\'\"" $$EP_ENDL

        # Create commands for cleaning the source directory and downloading the source archive.
        command += "rm -rf $$SOURCE_DIR/*" $$EP_ENDL
        command += "cd $$SOURCE_DIR" $$EP_ENDL

        WGET_OPTIONS = "--max-redirect 10 --content-disposition --quiet --show-progress"
        command += "wget $$WGET_OPTIONS $$URL || exit 2" $$EP_ENDL

        # Create commands for printing the messages of extract sub-step.
        command += "echo \"-- extracting...\"" $$EP_ENDL
        command += "echo \"    src=\'$$SOURCE_DIR/`ls | head -1`'\"" $$EP_ENDL
        command += "echo \"    dst=\'$$BUILD_DIR\'\"" $$EP_ENDL

        # Create commands for cleaning the build directory and extracting the source archive.
        STRIP = $$3
        !isEmpty(STRIP) {
            STRIP = "--strip $$STRIP"
        }

        command += "rm -rf $$BUILD_DIR/*" $$EP_ENDL
        command += "tar xzvf `ls | head -1` -C $$BUILD_DIR $$STRIP || exit 2" $$EP_ENDL

        # Create commands for marking this step and removing the mark of build step.
        command += "echo -n \"\" > $$STAMP_FILE" $$EP_ENDL
        command += "rm -f" $$replace(STAMP_FILE, "-download", "-build")
    }
    else:win32 {
        error("Microsoft Windows platform is not supported yet.")
    }
    else {
        error("Unknown platform.")
    }

    # Return the generated command script.
    return($$command)
}

# Generates a command script for configuring, building and installing the previously downloaded
# source.
#
# param 1 The name of the custom target.
# param 2 Command for configuring the build system of the source.
# param 3 Command for building the source.
# param 4 Command for installing the built libraries.
# return The command script for for configuring, building and installing the source.
defineReplace(EP_BuildStep) {
    NAME = $$1
    CONFIG_CMD = $$2
    BUILD_CMD = $$3
    INSTALL_CMD = $$4

    # Check the preconditions for script generating.
    isEmpty(NAME) {
        error("Usage: EP_BuildStep(<name>, [<config_cmd>], [<build_cmd>], [<install_cmd>])")
    }

    # Generate command script for the appropriate platform.
    unix {
        BUILD_DIR = "$$EP_BASE/Build/$$NAME"
        STAMP_FILE = "$$EP_BASE/Stamp/$$NAME/$${NAME}-build"

        # Create guard command for skipping this step if the sources are already built.
        command = "if [ -f $$STAMP_FILE ]; then exit 0; fi" $$EP_ENDL

        # Create commands for performing all presented sub-steps.
        command += "cd $$BUILD_DIR" $$EP_ENDL

        isEmpty(CONFIG_CMD) {
            STEP = $$EP_Emphasize("No configure step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
        }
        else {
            STEP = $$EP_Emphasize("Performing configure step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
            command += "$$CONFIG_CMD || exit 2" $$EP_ENDL
        }

        isEmpty(BUILD_CMD) {
            STEP = $$EP_Emphasize("No build step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
        }
        else {
            STEP = $$EP_Emphasize("Performing build step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
            command += "$$BUILD_CMD || exit 2" $$EP_ENDL
        }

        isEmpty(INSTALL_CMD) {
            STEP = $$EP_Emphasize("No install step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
        }
        else {
            STEP = $$EP_Emphasize("Performing install step for \'$$NAME\'")
            command += "echo \"$$STEP\"" $$EP_ENDL
            command += "$$INSTALL_CMD || exit 2" $$EP_ENDL
        }

        # Create commands for marking this step.
        command += "echo -n \"\" > $$STAMP_FILE"
    }
    else:win32 {
        error("Microsoft Windows platform is not supported yet.")
    }
    else {
        error("Unknown platform.")
    }

    # Return the generated command script.
    return($$command)
}
