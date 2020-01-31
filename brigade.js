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
})

events.on("push", (brigadeEvent, project) => {
  console.log("Hello push event!!!")
  var docker = JSON.parse(brigadeEvent.payload)
  console.log(docker)
});

events.on("image_push", (e, p) => {
  var docker = JSON.parse(e.payload)
  console.log(docker)
});
