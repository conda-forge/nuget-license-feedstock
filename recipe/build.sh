#!/usr/bin/env bash

set -o xtrace -o nounset -o pipefail -o errexit

mkdir -p ${PREFIX}/libexec/${PKG_NAME}

framework_version="$(dotnet --version | sed -e 's/\..*//g').0"

# Build package with dotnet build
dotnet publish --no-self-contained src/NuGetUtility/NuGetUtility.csproj --output ${PREFIX}/libexec/${PKG_NAME} --framework net${framework_version}

tee ${PREFIX}/libexec/${PKG_NAME}/NuGetUtility.runtimeconfig.json << EOF
{
  "runtimeOptions": {
    "tfm": "net${framework_version}",
    "framework": {
      "name": "Microsoft.NETCore.App",
      "version": "${framework_version}.0"
    }
  }
}
EOF

mkdir -p ${PREFIX}/bin
rm -rf ${PREFIX}/libexec/${PKG_NAME}/NuGetUtility

# Create bash and batch wrappers for dotnet-project-licenses
tee ${PREFIX}/bin/dotnet-project-licenses << EOF
#!/bin/sh
exec \${DOTNET_ROOT}/dotnet exec %CONDA_PREFIX%/libexec/nuget-license/NuGetUtility.dll "\$@"
EOF

tee ${PREFIX}/bin/dotnet-project-licenses.cmd << EOF
call %DOTNET_ROOT%\dotnet exec %CONDA_PREFIX%\libexec\nuget-license\NuGetUtility.dll %*
EOF

# Use newly build dotnet-project-licenses to get dependency licenses for this project.
chmod +x ${PREFIX}/bin/dotnet-project-licenses
${PREFIX}/bin/dotnet-project-licenses --input . -t -d license-files
