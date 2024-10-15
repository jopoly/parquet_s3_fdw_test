#!/bin/bash

# Save the list of existing environment variables before sourcing the env_rpmbuild.conf file.
before_vars=$(compgen -v)

source rpm/env_rpmbuild.conf

# Save the list of environment variables after sourcing the env_rpmbuild.conf file
after_vars=$(compgen -v)

# Find new variables created from configuration file
new_vars=$(comm -13 <(echo "$before_vars" | sort) <(echo "$after_vars" | sort))

# Export variables so that scripts or child processes can access them
for var in $new_vars; do
    export "$var"
done

set -eE

# validate parameters
chmod a+x rpm/validate_parameters.sh
./rpm/validate_parameters.sh AWS_S3_CPP_VERSION ARROW_VERSION IMAGE_TAG DOCKERFILE ARTIFACT_DIR_WITH_POSTGRES proxy no_proxy PACKAGE_RELEASE_VERSION POSTGRESQL_VERSION PARQUET_S3_FDW_RELEASE_VERSION

# download aws-sdk and arrow packages
# clone aws s3
if [[ ! -d "rpm/deps/aws_s3_cpp/aws-sdk-cpp-$AWS_S3_CPP_VERSION" ]]; then
	cd rpm/deps/aws_s3_cpp
	chmod -R 777 ./
	git clone --depth 1 --recursive --branch $AWS_S3_CPP_VERSION https://github.com/aws/aws-sdk-cpp.git aws-sdk-cpp-$AWS_S3_CPP_VERSION
	tar -czvf aws-sdk-cpp.tar.bz2 aws-sdk-cpp-$AWS_S3_CPP_VERSION
	cd ../../..
fi

# clone arrow
if [[ ! -f "rpm/deps/arrow/apache-arrow-$ARROW_VERSION.tar.gz" ]]; then
	cd rpm/deps/arrow
	chmod -R 777 ./
	wget https://github.com/apache/arrow/archive/refs/tags/apache-arrow-$ARROW_VERSION.tar.gz --no-check-certificate
	cd ../../..
fi

# get base PostgreSQL version
POSTGRESQL_BASE_VERSION=$(echo "$POSTGRESQL_VERSION" | cut -d '.' -f 1)

# create rpm on container environment
docker build -t $IMAGE_TAG \
                --build-arg proxy=${proxy} \
                --build-arg no_proxy=${no_proxy} \
                --build-arg PACKAGE_RELEASE_VERSION=${PACKAGE_RELEASE_VERSION} \
                --build-arg POSTGRESQL_BASE_VERSION=${POSTGRESQL_BASE_VERSION} \
                --build-arg POSTGRESQL_VERSION=${POSTGRESQL_VERSION} \
                --build-arg PARQUET_S3_FDW_RELEASE_VERSION=${PARQUET_S3_FDW_RELEASE_VERSION} \
                --build-arg AWS_S3_CPP_VERSION=${AWS_S3_CPP_VERSION} \
                --build-arg ARROW_VERSION=${ARROW_VERSION} \
                -f rpm/$DOCKERFILE .

# copy binary to outside
mkdir -p $ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION
docker run --rm -v $(pwd)/$ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "sudo chmod 777 /tmp && cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $ARTIFACT_DIR_WITH_POSTGRES/$POSTGRESQL_BASE_VERSION/*-debuginfo-*.rpm

# Clean
docker rmi $IMAGE_TAG
