# python-batch-file
Simple .bat file to run python scripts on windows in a virtual environment

This script checks if a virtual environment is available, creates one if not.

Checks that all the correct packges are installed and installs them if not.

Checks that the correct base version of python is being used and raises a warning if not.

Runs the script from the available or installed venv.

On the initial run, the user is asked to specify the python path.
