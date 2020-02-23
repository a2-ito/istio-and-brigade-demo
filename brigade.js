const { events, Job } = require("brigadier");

events.on("exec", () => {
  /*
	var job = new Job("do-nothing", "alpine:3.8");
  job.tasks = [
    "echo Hello",
    "echo World"
  ];
  job.run();
	*/
  console.log("Hello World!!!")
/*
	brigConfig.set("dhubServer", project.secrets.dhubServer)
  brigConfig.set("dhubUsername", project.secrets.dhubUsername)
  brigConfig.set("dhubPassword", project.secrets.dhubPassword)
  brigConfig.set("apiImage", "a2ito/smackapi")
	//brigConfig.set("gitSHA", brigadeEvent.commit.substr(0,7))
  brigConfig.set("gitSHA", "hogehoge")
	//brigConfig.set("eventType", brigadeEvent.type)
  //brigConfig.set("branch", getBranch(gitPayload))
  brigConfig.set("branch", "master")
	brigConfig.set("imageTag", `${brigConfig.get("branch")}-${brigConfig.get("gitSHA")}`)
  brigConfig.set("apiDHBImage", `${brigConfig.get("apiImage")}`)
  //brigConfig.set("apiDHBImage", `${brigConfig.get("dhubServer")}/${brigConfig.get("apiImage")}`)

  var docker = new Job("job-runner-docker")
  dockerJobRunner(brigConfig, docker)

  var pipeline = new Group()
  pipeline.add(docker)
  if (brigConfig.get("branch") == "master") {
    pipeline.runEach()
  } else {
    console.log(`==> no jobs to run when not master`)
  }  
*/
})

events.on("push", (brigadeEvent, project) => {
  console.log("Hello push event!!!")
  var payload = JSON.parse(brigadeEvent.payload)
  console.log(payload)
});

function dockerJobRunner(config, d) {
    d.storage.enabled = false
    d.image = "lachlanevenson/k8s-helm:2.7.0"
    d.tasks = [
      `helm upgrade --install kaniko ./charts/kaniko --set api.image=${config.get("apiDHBImage")} --set api.imageTag=${config.get("imageTag")} --set api.deployment=smackapi-${deployType} --set api.versionLabel=${deployType}`
    ]
}

function helmJobRunner (config, h, prodWeight, canaryWeight, deployType) {
    h.storage.enabled = false
    h.image = "lachlanevenson/k8s-helm:2.7.0"
    h.tasks = [
        "cd /src/",
        `helm upgrade --install smackapi-${deployType} ./charts/smackapi --namespace microsmack --set api.image=${config.get("apiACRImage")} --set api.imageTag=${config.get("imageTag")} --set api.deployment=smackapi-${deployType} --set api.versionLabel=${deployType}`,
        `helm upgrade --install microsmack-routes ./charts/routes --namespace microsmack --set prodLabel=prod --set prodWeight=${prodWeight} --set canaryLabel=new --set canaryWeight=${canaryWeight}`
    ]
}

events.on("image_push", (e, p) => {
  var docker = JSON.parse(e.payload)
  console.log(docker)
});
