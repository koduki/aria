load 'lib/powershell.rb'
ps = PowerShell.new



r = ps.invoke("echo Hello")
p r

require 'json'

require_relative './gemini/gemini'

@api_key = File.read(File.join(Dir.home, '.secret', 'gemini.txt')).strip
sysprompt = open('prompts/powershell.txt').read
client = Gemini::Gemini.new(
credentials: {
    service: 'generative-language-api',
    api_key: @api_key
},
options: { model: 'gemini-2.0-flash-exp', system_instruction:sysprompt, json_mode:true}
)

contents='Videoディレクトリの7月の動画をフォルダにまとめて'
r = client.generate_content({
    contents: [{ role: 'user', parts: [{ text: contents }] }]
})

# puts r[:response]["content"]["parts"][0]["text"]

def parse(text)
    trimed_data = text.sub(/\A```json\s*/, '').sub(/\s*```\z/, '')
    JSON.parse(trimed_data)
end

# p r


response = parse(r[:response]["content"]["parts"][0]["text"])

# puts response["thinking"]
task = response["task"]
# p task
# r = ps.invoke(task)
# p r


# テストコード例
# result = ps.invoke("$videoPath = [Environment]::GetFolderPath('MyVideos'); " \
#                 "$source = Join-Path $videoPath '2024年7月'; " \
#                 "if (!(Test-Path -Path $source)) { Write-Host 'Source directory does not exist.' }; " \
#                 "Get-ChildItem -Path $source")
# puts "Result: #{result[:stdout]}"

multiline_command = <<~POWERSHELL
$x = 10
$y = 20
Write-Host ($x + $y)
POWERSHELL
p multiline_command
p ps.invoke('$videoPath = [Environment]::GetFolderPath(\'MyVideos\')\n$targetFolderName = \'7月動画\'\n$targetPath = Join-Path -Path $videoPath -ChildPath $targetFolderName\nif (!(Test-Path -Path $targetPath)) {\n  New-Item -ItemType Directory -Path $targetPath\n}\nGet-ChildItem -Path $videoPath -File | Where-Object {$_.LastWriteTime.Month -eq 7} | ForEach-Object {Move-Item -Path $_.FullName -Destination $targetPath}')