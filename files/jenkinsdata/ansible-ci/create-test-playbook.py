# This file reads an example.yml Playbook from the command line,
# substitutes the 'hosts' variables in all plays with 'acia.vm' and writes
# the result to a 'playbook.yml' file in the execution directory

from sys import argv
import yaml
import os.path

script,playbook = argv

infile = open(playbook)
content = infile.read()
infile.close()

vexdata = ['.vault']
if os.path.isfile('aci/varsfilesexcludes'):
    vexfile = open('aci/varsfilesexcludes')
    vexdata = vexfile.read().splitlines()
    vexfile.close()

data = yaml.load(content)

for play in data:
  play['hosts'] = 'acia.vm'
  if 'vars_files' in play:
      playbook_vars_files = list(play['vars_files'])
      for vars_files_entry in playbook_vars_files:
          for exclude_pattern in vexdata:
              if exclude_pattern in vars_files_entry:
                  play['vars_files'].remove(vars_files_entry)
  if os.path.isfile('aci/vars.yml'):
      if 'vars_files' not in play:
        play['vars_files']=[]
      play['vars_files'].append('aci/vars.yml')


## uncomment to print results on console
#print yaml.dump(data, default_flow_style=False)

outfile = open('aci-playbook.yml','w+')
outfile.write(yaml.dump(data))
outfile.close()
