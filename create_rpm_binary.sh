#!/bin/bash

source env_rpmbuild.conf
set -eE

# download aws-sdk and arrow packages
# clone aws s3
if [[ ! -d "deps/aws_s3_cpp/aws-sdk-cpp-$AWS_S3_CPP_VERSION" ]]; then
	cd deps/aws_s3_cpp
	chmod -R 777 ./
	git clone --depth 1 --recursive --branch $AWS_S3_CPP_VERSION https://github.com/aws/aws-sdk-cpp.git aws-sdk-cpp-$AWS_S3_CPP_VERSION
	tar -czvf aws-sdk-cpp.tar.bz2 aws-sdk-cpp-$AWS_S3_CPP_VERSION
	cd ../..
fi

# clone arrow
if [[ ! -f "deps/arrow/apache-arrow-$ARROW_VERSION.tar.gz" ]]; then
	cd deps/arrow
	chmod -R 777 ./
	wget https://github.com/apache/arrow/archive/refs/tags/apache-arrow-$ARROW_VERSION.tar.gz --no-check-certificate
	cd ../..
fi

if [[ ${PGSPIDER_RPM_ID} ]]; then
    PGSPIDER_RPM_ID_POSTFIX="-${PGSPIDER_RPM_ID}"
fi

# create rpm on container environment
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then 
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg ACCESS_TOKEN=${ACCESS_TOKEN} \
                 --build-arg DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg PGSPIDER_PROJECT_ID=$PGSPIDER_PROJECT_ID \
                 --build-arg PGSPIDER_BASE_POSTGRESQL_VERSION=${PGSPIDER_BASE_POSTGRESQL_VERSION} \
                 --build-arg PGSPIDER_RELEASE_VERSION=${PGSPIDER_RELEASE_VERSION} \
                 --build-arg PARQUET_S3_FDW_RELEASE_VERSION=${PARQUET_S3_FDW_RELEASE_VERSION} \
                 --build-arg AWS_S3_CPP_VERSION=${AWS_S3_CPP_VERSION} \
                 --build-arg ARROW_VERSION=${ARROW_VERSION} \
                 --build-arg PGSPIDER_RPM_ID=${PGSPIDER_RPM_ID_POSTFIX} \
                 -f $DOCKERFILE .
else
    docker build -t $IMAGE_TAG \
                 --build-arg proxy=${proxy} \
                 --build-arg no_proxy=${no_proxy} \
                 --build-arg DISTRIBUTION_TYPE=${RPM_DISTRIBUTION_TYPE} \
                 --build-arg PGSPIDER_PROJECT_ID=$PGSPIDER_PROJECT_ID \
                 --build-arg PGSPIDER_BASE_POSTGRESQL_VERSION=${PGSPIDER_BASE_POSTGRESQL_VERSION} \
                 --build-arg PGSPIDER_RELEASE_VERSION=${PGSPIDER_RELEASE_VERSION} \
                 --build-arg PARQUET_S3_FDW_RELEASE_VERSION=${PARQUET_S3_FDW_RELEASE_VERSION} \
                 --build-arg AWS_S3_CPP_VERSION=${AWS_S3_CPP_VERSION} \
                 --build-arg ARROW_VERSION=${ARROW_VERSION} \
                 --build-arg PGSPIDER_RPM_ID=${PGSPIDER_RPM_ID_POSTFIX} \
                 -f $DOCKERFILE .
fi

# copy binary to outside
mkdir -p $RPM_ARTIFACT_DIR
docker run --rm -v $(pwd)/$RPM_ARTIFACT_DIR:/tmp \
                -u "$(id -u $USER):$(id -g $USER)" \
                -e LOCAL_UID=$(id -u $USER) \
                -e LOCAL_GID=$(id -g $USER) \
                $IMAGE_TAG /bin/sh -c "cp /home/user1/rpmbuild/RPMS/x86_64/*.rpm /tmp/"
rm -f $RPM_ARTIFACT_DIR/*-debuginfo-*.rpm

# Push binary on repo
if [[ $location == [gG][iI][tT][lL][aA][bB] ]];
then
    curl_command="curl --header \"PRIVATE-TOKEN: ${ACCESS_TOKEN}\" --insecure --upload-file"
    package_uri="https://tccloud2.toshiba.co.jp/swc/gitlab/api/v4/projects/${PARQUET_S3_FDW_PROJECT_ID}/packages/generic/rpm_${RPM_DISTRIBUTION_TYPE}/${PGSPIDER_BASE_POSTGRESQL_VERSION}"

    # aws_s3_cpp
    eval "$curl_command ${RPM_ARTIFACT_DIR}/arrow-${ARROW_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/arrow-${ARROW_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # arrow
    eval "$curl_command ${RPM_ARTIFACT_DIR}/aws_s3_cpp-${AWS_S3_CPP_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/aws_s3_cpp-${AWS_S3_CPP_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # parquet_s3_fdw
    eval "$curl_command ${RPM_ARTIFACT_DIR}/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # debugsource
    eval "$curl_command ${RPM_ARTIFACT_DIR}/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $package_uri/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
else
    curl_command="curl -L \
                            -X POST \
                            -H \"Accept: application/vnd.github+json\" \
                            -H \"Authorization: Bearer ${ACCESS_TOKEN}\" \
                            -H \"X-GitHub-Api-Version: 2022-11-28\" \
                            -H \"Content-Type: application/octet-stream\" \
                            --insecure"
    assets_uri="https://uploads.github.com/repos/${OWNER_GITHUB}/${PARQUET_S3_FDW_PROJECT_GITHUB}/releases/${PARQUET_S3_FDW_RELEASE_ID}/assets"
    binary_dir="--data-binary \"@${RPM_ARTIFACT_DIR}\""

    # aws_s3_cpp
    eval "$curl_command $assets_uri?name=arrow-${ARROW_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/arrow-${ARROW_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # arrow
    eval "$curl_command $assets_uri?name=aws_s3_cpp-${AWS_S3_CPP_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/aws_s3_cpp-${AWS_S3_CPP_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # parquet_s3_fdw
    eval "$curl_command $assets_uri?name=parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
    # debugsource
    eval "$curl_command $assets_uri?name=parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm \
                        $binary_dir/parquet_s3_fdw_${PGSPIDER_BASE_POSTGRESQL_VERSION}-debugsource-${PARQUET_S3_FDW_RELEASE_VERSION}-${RPM_DISTRIBUTION_TYPE}.x86_64.rpm"
fi

# Clean
docker rmi $IMAGE_TAG
