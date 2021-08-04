# FROM instruction chooses the parent image for Docker.
# I was using python 3.8 slim buster but maybe miniconda
# is a better choice
#FROM python:3.8-slim-buster
FROM continuumio/miniconda3

# LABEL instruction creates labels.
# The first label is maintainer with the value Tyler Pierce
# The second label is appname with the value dymos with snopt.
# You can have as many key-to-value pairs as you want.
# You can also choose any name for the keys.
# The choice of maintainer and appname in this example
# is a personal choice.

LABEL "maintainer"="Tyler Pierce" "appname"="dymos with snopt"

# ENV instruction assigns environment variables.
# The /usr/src directory holds downloaded programs,
# be it source or binary before installing them.
# The command below uses the set environment variable.
ENV applocation /usr/src

# COPY instruction copies files or directories,
# from the Docker host to the Docker image.
# You'll copy the source code to the Docker image.

# Copy over libsnopt7 folder and libsnopt7_cpp folder from zip files I extracted

# This doesn't work the way I think it did. 
#COPY /home/tpierce/lib/libsnopt* $applocation/
#COPY /home/tpierce/lib/snopt7.lic $applocation/
#I have libsnopt7 libsnopt7_cpp libsqopt7 libsqopt7_cpp snop7.lic sqopt7.lic
#I don't have any .f files in these folders. Maybe I need to get the fortran version?

# Maybe need to use ENV again here for some things?.
#ENV snopt7_license $applocation/snopt7.lic
SHELL ["/bin/bash", "-c"]
RUN conda init bash
RUN conda config --set always_yes yes --set changeps1 no
RUN conda create --yes -n PY3.8 python=3.8

# conda needs to iniate bash but doesn't know where the bash is coming from in docker
# in order to keep conda activated with bash this is the best workaround I found
RUN echo "conda activate PY3.8" >> ~/.bashrc
SHELL ["/bin/bash", "--login", "-c"]

# Other method I tried doesn't work
#RUN conda init bash
#RUN conda activate PY3.8

# Add conda-forge to get some packages
RUN conda config --add channels conda-forge
RUN conda install --yes cython sphinx mock swig pip numpy scipy mpi4py matplotlib

# pyoptsparse was recently added to conda-forge so this seems like the easiest way to get it
# I'm wondering if installing pyoptspare this way is going to work if I want SNOPT
RUN conda install -c conda-forge pyoptsparse

# Install and update apt-get and get a bunch of base apps I need.
# Currently works in this order but maybe should have this at the start
RUN apt-get -y update && apt-get install -y --no-install-recommends \
curl \
gcc \
gpp \
wget \
g++ \
swig \
make \
gfortran \
git \
&& rm -rf /var/lib/apt/lists*
# idk exactly if the rm command above is necessary but I see it a lot

RUN python -m pip install --upgrade pip;
RUN python -m pip install sqlitedict;
RUN python -m pip install nose;
RUN python -m pip install networkx;
# using testflo 1.3.6 based on yaml file, maybe newer is better
RUN python -m pip install testflo==1.3.6;
RUN python -m pip install pyyaml;
RUN python -m pip install coveralls;
RUN python -m pip install bokeh;

# not sure if I need any of these
RUN python -m pip install mkdocs
RUN python -m pip install mkdocs-material
RUN python -m pip install pymdown-extensions
RUN python -m pip install mkdocs-macros-plugin
RUN python -m pip install mkdocs-bibtex
RUN python -m pip install mike

# RUN instruction runs commands,
# just like you do on the terminal,
# but in the Docker image.
# The command below installs Python, pip and the app dependencies.
# The dependencies are in the requirements.txt file.
#RUN apk add --update python py-pip #not necessary but show for example
#RUN pip install --upgrade pip
#RUN pip install -r requirements.txt #don't have this maybe should

RUN git clone https://github.com/OpenMDAO/MBI.git $applocation/MBI
WORKDIR $applocation/MBI
RUN python setup.py build install
WORKDIR $applocation
RUN conda install --yes petsc4py

RUN git clone https://github.com/OpenMDAO/OpenMDAO.git $applocation/OpenMDAO
WORKDIR OpenMDAO
RUN pip install -e .[all]
WORKDIR $applocation

RUN git clone https://github.com/OpenMDAO/dymos.git $applocation/dymos
WORKDIR $applocation/dymos
RUN python -m pip install -e .[all]

WORKDIR $applocation
RUN conda list > conda.list.txt

RUN export LD_LIBRARY_PATH=/usr/src/ipopt/lib
RUN dymos_path=$(python -c "import dymos as dm; import inspect; import pathlib; p=pathlib.PurePath(inspect.getfile(dm)).parent; print(p)" | tail -1)
RUN export OMPI_MCA_rmaps_base_oversubscribe=1
#RUN testflo $dymos_path -n 1 --show_skipped --coverage --coverpkg dymos;
#RUN testflow -n 1 --show_skipped --coverage --coverpkg dymos;
#RUN testflo -n 1 joss/test --pre_announce
#RUN testflo -b benchmark --pre_announce

#RUN pip install 'openmdao[all]'
#RUN git clone https://github.com/OpenMDAO/dymos.git ./dymos.git
#RUN python -m pip install -e dymos.git[all]
#RUN git clone https://github.com/OpenMDAO/build_pyoptsparse.git ./build_pyoptsparse

# # WORKDIR instruction changes the current directory in Docker image.
# The command below changes directory to build_pyoptspare
# The target directory uses the environment variable.
#ENV buildpyopt ./build_pyoptspare
#WORKDIR build_pyoptsparse
# I think you can also just do this:
#RUN cd build_pyoptspare

# EXPOSE instruction opens the port for communicating with the Docker container.
# app uses the port 5000, so you'll expose port 5000.
EXPOSE 5000

# CMD instruction runs commands like RUN,
# but the commands run when the Docker container launches.
# Only one CMD instruction can be used.
#RUN pwd
#RUN ls
#RUN chmod +x build_pyoptspare.sh
#CMD ["./build_pyoptspare.sh SNOPT=7.7 -s $applocation/libsnopt7/", "app.py"]


# Volume is the mechanism for persisting data /app
VOLUME /app/
WORKDIR /app/
