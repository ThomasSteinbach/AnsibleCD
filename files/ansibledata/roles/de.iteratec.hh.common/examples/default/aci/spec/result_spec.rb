describe package('python') do
  it { should be_installed }
end

describe package('python-pip') do
  it { should be_installed }
end

describe package('python-httplib2') do
  it { should be_installed }
end

describe package('vim') do
  it { should be_installed }
end

describe command('date') do
  its(:stdout) { should match 'CES?T' }
end
