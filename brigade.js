const { events, Job, Group } = require("brigadier");

events.on("push", (brigadeEvent, project) => {

  console.log("Hello push event!!!")
  //var payload = JSON.parse(brigadeEvent.payload)
  //console.log(payload)

  var brigConfig = new Map()

	brigConfig.set("apiImage", "a2ito/smackapi")
	brigConfig.set("gitSHA", brigadeEvent.revision.commit.substr(0,7))
	brigConfig.set("eventType", brigadeEvent.type)
  //console.log(brigadeEvent.payload.head.ref)
  console.log(brigadeEvent.revision.ref)
  brigConfig.set("branch", brigadeEvent.revision.ref.split('/').pop())
	brigConfig.set("imageTag", `${brigConfig.get("branch")}-${brigConfig.get("gitSHA")}`)
  brigConfig.set("apiDHBImage", `${brigConfig.get("apiImage")}`)
  //brigConfig.set("apiDHBImage", `${brigConfig.get("dhubServer")}/${brigConfig.get("apiImage")}`)

  var docker = new Job("job-runner-docker")
  var helm = new Job("job-runner-helm")
  //var helmnew = new Job("job-runner-helm")
  //docker.serviceAccount = "tiller"
  console.log("imageTag: ", `${brigConfig.get("imageTag")}`)
	dockerJobRunner(brigConfig, docker)
  helmJobRunner(brigConfig, helm, 100, 0, "prod")
  //helmJobRunner(brigConfig, helmnew, 100, 0, "new")

  var pipeline = new Group()
  pipeline.add(docker)
  pipeline.add(helm)
  //pipeline.add(helmnew)
  if (brigConfig.get("branch") == "master") {
    pipeline.runEach()
  } else {
    console.log(`==> no jobs to run when not master`)
  }  

  //var helmnew = new Job("job-runner-helmnew")
  //helmJobRunner(brigConfig, helmnew, 100, 0, "new")
  //helm.run() 

})

events.on("pull_request", (brigadeEvent, project) => {

  var brigConfig = new Map()
	brigConfig.set("apiImage", "a2ito/smackapi")
	brigConfig.set("gitSHA", brigadeEvent.revision.commit.substr(0,7))
	brigConfig.set("eventType", brigadeEvent.type)
  console.log(JSON.parse(brigadeEvent.payload).pull_request.head.ref)
  console.log(brigadeEvent.revision.ref)
  brigConfig.set("branch", JSON.parse(brigadeEvent.payload).pull_request.head.ref)
	brigConfig.set("imageTag", `${brigConfig.get("branch")}-${brigConfig.get("gitSHA")}`)
  brigConfig.set("apiDHBImage", `${brigConfig.get("apiImage")}`)

  var docker = new Job("job-runner-docker")
  var helm = new Job("job-runner-helm")
	dockerJobRunner(brigConfig, docker)
  helmJobRunner(brigConfig, helm, 90, 10, "new")
  //docker.serviceAccount = "tiller"
  var pipeline = new Group()
  pipeline.add(docker)
  pipeline.add(helm)
  pipeline.runEach()

})

events.on("exec", () => {

  var brigConfig = new Map()
	brigConfig.set("apiImage", "a2ito/smackapi")
	//brigConfig.set("gitSHA", brigadeEvent.revision.commit.substr(0,7))
	//brigConfig.set("eventType", brigadeEvent.type)
  //brigConfig.set("branch", brigadeEvent.revision.ref.split('/').pop())
	//brigConfig.set("imageTag", `${brigConfig.get("branch")}-${brigConfig.get("gitSHA")}`)
	brigConfig.set("imageTag", "hoge-hoge-3")
  brigConfig.set("apiDHBImage", `${brigConfig.get("apiImage")}`)

  var docker = new Job("job-runner-docker")
  var helm = new Job("job-runner-helm")
	dockerJobRunner(brigConfig, docker)
  helmJobRunner(brigConfig, helm, 100, 0, "prod")
  //docker.serviceAccount = "tiller"
  var pipeline = new Group()
  pipeline.add(docker)
  pipeline.add(helm)
  pipeline.runEach()

})

function dockerJobRunner(config, d) {
    d.storage.enabled = false
    d.image = "lachlanevenson/k8s-helm:2.7.0"
    d.tasks = [
			"cd /src/",
      `helm upgrade --install kaniko ./charts/kaniko --force --set api.image=${config.get("apiDHBImage")} --set api.imageTag=${config.get("imageTag")} --set api.branch=${config.get('branch')}`
    ]
}

function helmJobRunner (config, h, prodWeight, canaryWeight, deployType) {
    h.storage.enabled = false
    h.image = "lachlanevenson/k8s-helm:2.7.0"
    h.tasks = [
        "cd /src/",
        `helm upgrade --install smackapi-${deployType} --force ./kube-con-2017-ito/charts/smackapi --namespace microsmack --set api.image=${config.get("apiDHBImage")} --set api.imageTag=${config.get("imageTag")} --set api.deployment=smackapi-${deployType} --set api.versionLabel=${deployType}`,
        `helm upgrade --install microsmack-routes --force ./kube-con-2017-ito/charts/routes --namespace microsmack --set prodLabel=prod --set prodWeight=${prodWeight} --set canaryLabel=new --set canaryWeight=${canaryWeight}`
    ]
}

events.on("image_push", (e, p) => {
  var docker = JSON.parse(e.payload)
  console.log(docker)
});
