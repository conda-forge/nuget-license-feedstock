#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/libexec/${PKG_NAME}

framework_version="$(dotnet --version | sed -e 's/\..*//g').0"

# Build package with dotnet build
dotnet publish --no-self-contained src/NuGetUtility/NuGetUtility.csproj --output ${PREFIX}/libexec/${PKG_NAME} --framework net${framework_version}

mkdir -p ${PREFIX}/bin
rm -rf ${PREFIX}/libexec/${PKG_NAME}/NuGetUtility

# Create bash and batch wrappers for dotnet-project-licenses
tee ${PREFIX}/bin/dotnet-project-licenses << EOF
#!/bin/sh
DOTNET_ROOT=${DOTNET_ROOT} exec ${DOTNET_ROOT}/dotnet exec ${PREFIX}/libexec/${PKG_NAME}/NuGetUtility.dll "\$@"
EOF

tee ${PREFIX}/bin/dotnet-project-licenses.cmd << EOF
call %DOTNET_ROOT%\dotnet exec %CONDA_PREFIX%\libexec\nuget-license\NuGetUtility.dll %*
EOF

# Use newly build dotnet-project-licenses to get dependency licenses for this project.
chmod +x ${PREFIX}/bin/dotnet-project-licenses
${PREFIX}/bin/dotnet-project-licenses --input . -t -d license-files
