# adp-postgres-migration


## Local Development

### Setting Up the Docker Environment

Ensure you have Docker installed on your system. If not, download and install Docker from [Docker's official website](https://www.docker.com/get-started).

### Building the Docker Image

To build the Docker image with your application, navigate to the directory containing your Dockerfile and run the following command:

```bash
docker build -t your-image-name:tag .
```

## Docker Image Versioning

Our Docker images follow semantic versioning (SemVer) to manage versions systematically. The `dockerImageVersion` specifies the version of the Docker image being used or published. Semantic versioning is a 3-component system in the format of `MAJOR.MINOR.PATCH`, where:

- `MAJOR` version increases make incompatible API changes,
- `MINOR` version increases add functionality in a backwards compatible manner, and
- `PATCH` version increases make backwards compatible bug fixes.

### Example

For instance, if the current `dockerImageVersion` is `1.0.0`:

- An update with backward-compatible bug fixes increments the PATCH: `1.0.1`
- A backward-compatible feature addition increments the MINOR: `1.1.0`
- An incompatible API change increments the MAJOR: `2.0.0`

### Updating `dockerImageVersion`

When contributing to the project or updating Docker images, ensure you update the `dockerImageVersion` in the `publish-docker-image.yaml` file according to the changes made. This practice helps in maintaining version control and backward compatibility of Docker images.

For more details on semantic versioning, visit [Semantic Versioning 2.0.0](https://semver.org/).

## Licence

THIS INFORMATION IS LICENSED UNDER THE CONDITIONS OF THE OPEN GOVERNMENT LICENCE found at:

<http://www.nationalarchives.gov.uk/doc/open-government-licence/version/3>

The following attribution statement MUST be cited in your products and applications when using this information.

> Contains public sector information licensed under the Open Government license v3

### About the licence

The Open Government Licence (OGL) was developed by the Controller of Her Majesty's Stationery Office (HMSO) to enable information providers in the public sector to license the use and re-use of their information under a common open licence.

It is designed to encourage use and re-use of information freely and flexibly, with only a few conditions.
