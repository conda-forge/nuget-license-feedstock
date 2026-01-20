#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/bin
mkdir -p ${PREFIX}/libexec/${PKG_NAME}
ln -sf ${DOTNET_ROOT}/dotnet ${PREFIX}/bin

rm -rf global.json
framework_version="$(dotnet --version | sed -e 's/\..*//g').0"

# Build package with dotnet build
dotnet publish --no-self-contained ${SRC_DIR}/src/NuGetLicenseCore/NuGetLicenseCore.csproj --configuration Release --output ${PREFIX}/libexec/${PKG_NAME} --framework net${framework_version}

mkdir -p ${PREFIX}/bin
rm -rf ${PREFIX}/libexec/${PKG_NAME}/NuGetLicenseCore

# Create bash and batch wrappers for dotnet-project-licenses
tee ${PREFIX}/bin/dotnet-project-licenses << EOF
#!/bin/sh
exec ${DOTNET_ROOT}/dotnet exec ${PREFIX}/libexec/nuget-license/NuGetLicenseCore.dll "\$@"
EOF
chmod +x ${PREFIX}/bin/dotnet-project-licenses

tee ${PREFIX}/bin/dotnet-project-licenses.cmd << EOF
call %DOTNET_ROOT%\dotnet exec %CONDA_PREFIX%\libexec\nuget-license\NuGetLicenseCore.dll %*
EOF

# Use newly build dotnet-project-licenses to get dependency licenses for this project.
chmod +x ${PREFIX}/bin/dotnet-project-licenses
${PREFIX}/bin/dotnet-project-licenses --input ${SRC_DIR}/src/NuGetLicenseCore/NuGetLicenseCore.csproj -t -d license-files

rm ${PREFIX}/bin/dotnet
