#file="/Users/sebastienvian/Desktop/LA BALLADE/Philippines 2/MVI_8854.MOV"
IFS=$'\n'
files=$(mdfind 'kMDItemUserTags == Violet');

aws s3 ls s3://la-ballade/videos/ | grep _35.mp4  > aws.tmp
#files=$(mdfind 'kMDItemUserTags == Violet');
for file in ${files}
do
echo "converting ${file} \n";


  filename="${file##*/}"
  if [[ $(cat aws.tmp | grep -c ${filename}) != 0 ]];then
   echo "exists skipping"
   continue
  fi
  


  output="${filename}_35.mp4"
  echo ${file};
  ffmpeg -i "${file}" -y -c:v libx264 -crf 35  "${output}";
  echo "uploading ${output} \n"
  aws s3 cp --acl public-read "${output}" s3://la-ballade/videos/
  rm "${output}"
done;
