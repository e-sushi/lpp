local options = assert(lake.getOptions())

local mode = options.mode or "debug"
local build_dir = lake.cwd().."/build/"..mode.."/"

options.registerCleaner(function()
	lake.rm(build_dir, {recursive = true, force = options.force_clean})
end)

lake.mkdir(build_dir, {make_parents = true})

local report = assert(options.report)
local reports = assert(options.reports)
local recipes = assert(options.recipes)


assert(reports.iro.objFiles, "lpp depends on iro's object files but they were not found in the reports table. Was iro's module imported? Maybe it was imported after this one.")

local lpp = lake.target(build_dir.."lpp")

report.executable(tostring(lpp))

local c_files = lake.find("src/**/*.cpp")

for c_file in c_files:each() do
	local o_file = c_file:gsub("(.-)%.cpp", build_dir.."%1.o")
	local d_file = o_file:gsub("(.-)%.o", "%1.d")

	report.objFile(o_file)

	lake.target(o_file)
		:dependsOn(c_file)
		:recipe(recipes.compiler(c_file, o_file))

	lake.target(d_file)
		:dependsOn(c_file)
		:recipe(recipes.depfile(c_file, d_file, o_file))
end

local ofiles = lake.flatten { reports.lpp.objFiles, reports.iro.objFiles }

lpp
	:dependsOn(ofiles)
	:recipe(recipes.linker(ofiles, lpp))

reports.getProjLibs("luajit"):each(function(e)
	lpp:dependsOn(e)
end)
