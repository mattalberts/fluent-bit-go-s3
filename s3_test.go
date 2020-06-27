package main

import (
	"errors"
	"testing"
	"time"

	"github.com/stretchr/testify/assert"
)

func TestGetS3ConfigStaticCredentials(t *testing.T) {
	conf, err := getS3Config("exampleaccessID", "examplesecretkey", "", "exampleprefix", "", "examplebucket", "exampleregion", "", "", "", "", "", "")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, plainTextFormat, conf.compress, "Specify compression method")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
}

func TestGetS3ConfigSharedCredentials(t *testing.T) {
	s3Creds = &testS3Credential{}
	conf, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "", "", "", "", "", "")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, plainTextFormat, conf.compress, "Specify compression method")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
}

func TestGetS3ConfigCompression(t *testing.T) {
	s3Creds = &testS3Credential{}
	conf, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "", "", "", "", "")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, gzipFormat, conf.compress, "Specify compression method")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
}

func TestGetS3ConfigEndpoint(t *testing.T) {
	s3Creds = &testS3Credential{}
	conf, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "http://localhost:9000", "false", "", "", "")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, gzipFormat, conf.compress, "Specify compression method")
	assert.Equal(t, "http://localhost:9000", conf.endpoint, "Specify correct endpoint")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
}

func TestGetS3ConfigInvalidEndpoint(t *testing.T) {
	s3Creds = &testS3Credential{}
	_, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "https://your-bucketname.s3.amazonaws.com", "false", "", "", "")
	if err != nil {
		expected := errors.New("endpoint is not supported for AWS S3, 'Endpoint' is for S3 compatible services, use 'Region' instead")
		assert.Equal(t, expected, err)
	}
}

func TestGetS3ConfigTimeFormat(t *testing.T) {
	s3Creds = &testS3Credential{}
	conf, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "", "", "", "dt=2006-01-02", "Asia/Tokyo")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, gzipFormat, conf.compress, "Specify compression method")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
	assert.Equal(t, "dt=2006-01-02", conf.timeFormat, "Specify time format")
	loc, _ := time.LoadLocation("Asia/Tokyo")
	assert.Equal(t, loc, conf.location, "Specify valid TimeZone")
}

func TestGetS3ConfigTimeZone(t *testing.T) {
	s3Creds = &testS3Credential{}
	conf, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "", "", "", "", "Asia/Tokyo")
	if err != nil {
		t.Fatalf("failed test %#v", err)
	}

	assert.Equal(t, "examplebucket", *conf.bucket, "Specify bucket name")
	assert.Equal(t, "exampleprefix", *conf.s3prefix, "Specify s3prefix name")
	assert.NotNil(t, conf.credentials, "credentials not to be nil")
	assert.Equal(t, "exampleregion", *conf.region, "Specify s3prefix name")
	assert.Equal(t, gzipFormat, conf.compress, "Specify compression method")
	assert.Equal(t, false, conf.autoCreateBucket, "Specify true/false")
	assert.Equal(t, "20060102/15", conf.timeFormat, "Specify time format")
	loc, _ := time.LoadLocation("Asia/Tokyo")
	assert.Equal(t, loc, conf.location, "Specify valid TimeZone")
}

func TestGetS3ConfigInvalidTimeZone(t *testing.T) {
	s3Creds = &testS3Credential{}
	_, err := getS3Config("", "", "examplecredentials", "exampleprefix", "", "examplebucket", "exampleregion", "gzip", "", "", "", "", "Asia/Nonexistent")
	if err != nil {
		expected := errors.New("invalid timeZone: unknown time zone Asia/Nonexistent")
		assert.Equal(t, expected, err)
	}
}
