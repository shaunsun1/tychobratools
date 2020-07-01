#'
#'
#' Deploy Shiny application
#' 
#' Deploy a Shiny application to a GCP VM instance (Must have gcloud on local machine).
#' Currently, this function MUST be run with the application in a `shiny_app` directory, & 
#' that directory should be in the Current Working Directory.
#' 
#' @param gcloud Absolute path for gcloud CLI (Ex: `/usr/local/bin/google-cloud-sdk/bin`)
#' @param deployed_dir_name Name of the directory in the VM instance for this app
#' @param instance_name The name of the VM instance
#' @param project_name The name of the GCP project for this VM instance
#' @param project_zone The zone of the GCP project for this VM instance
#' 
#' @importFrom config get
#' 
#' @section Example:
#' \preformatted{
#'   deploy_app(
#'     gcloud = '/usr/local/bin/google-cloud-sdk/bin',
#'     deployed_dir_name = 'example_app',
#'     instance_name = 'instance-1',
#'     project_name = 'gcp-project',
#'     project_zone = 'us-east1-d'
#'   )
#' 
#' }
#' 
#' @export
#' 
deploy_app <- function(
  gcloud = NULL,
  deployed_dir_name = config::get(file = 'shiny_app/config.yaml')$app_name,
  instance_name = NULL,
  project_name = 'postgres-db-189513',
  project_zone = 'us-east1-d'
) {
  
  if (!is.null(gcloud)) {
    Sys.setenv(PATH = paste(Sys.getenv('PATH'), gcloud, sep = ":"))
  }
  
  if (is.null(deployed_dir_name)) {
    stop("Argument `deployed_dir_name` is NULL")
  }
  
  # create new "restart.txt" file so that the app automatically restarts once deployed
  write(NULL, file = "shiny_app/restart.txt")
  
  # gcloud so set the project
  command_set_proj <- paste0("gcloud config set project ", project_name)
  system(command_set_proj)


  # gcloud SSH command to remove app if it already exists
  command_1 <- paste0("if [ -d /srv/shiny-server/", deployed_dir_name, " ]; then sudo rm -rf /srv/shiny-server/", deployed_dir_name, "; fi")
  command_arg <- paste0('--command="', command_1, '"')
  system2("gcloud", args = c("compute", "ssh", instance_name, "--zone", project_zone, command_arg))


  # Create the target directory to copy into. This doesn't seem like it should be necessary,
  # but gcloud scp has a problem if it doesn't exist.
  command_mkdir = paste0('--command="mkdir /srv/shiny-server/', deployed_dir_name, '"')
  system2("gcloud", args = c("compute", "ssh", instance_name, "--zone", project_zone, command_mkdir))

  # gcloud SCP command to copy local contents in 'shiny_app' directory to new 'deployed_dir_name' directory in VM
  instance_command <- paste0('"', instance_name, ':/srv/shiny-server/', deployed_dir_name, '"')
  system2("gcloud", args = c("compute", "scp", "--recurse", file.path("shiny_app", "*"), instance_command, "--zone", project_zone))
}