import {
  createNetwork,
  createTestExecutor,
  curl,
  startContainer,
  TestExecutor,
  waitForHttpOk,
} from "@capraconsulting/cals-cli"
import * as fs from "fs"

async function getExpectedVersion() {
  return (await fs.promises.readFile("Dockerfile", "utf-8"))
    .split("\n")
    .filter((it) => it.includes("ARG NEXUS_VERSION="))[0]
    .replace(/.*=([^\s]+)$/, "$1")
}

async function main(executor: TestExecutor) {
  if (process.argv.length !== 3) {
    throw new Error(`Syntax: ${process.argv[0]} ${process.argv[1]} <image-id>`)
  }

  const imageId = process.argv[2]
  const network = await createNetwork(executor)

  const service = await startContainer({
    executor,
    network,
    imageId,
    alias: "service",
  })

  await waitForHttpOk({
    container: service,
    url: "service:8081",
  })

  const expectedVersion = await getExpectedVersion()
  console.log(`Checking for version: ${expectedVersion}`)

  const response = await curl(executor, network, "-fS", "service:8081")
  if (!response.includes(expectedVersion)) {
    throw new Error("Did not find expected version")
  }
}

createTestExecutor().runWithCleanupTasks(main)
