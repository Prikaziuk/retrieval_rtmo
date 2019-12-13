t = Tiff('test.tif', 'w');
tagstruct = struct();
tagstruct.ImageLength = size(b1,1);
tagstruct.ImageWidth = size(b1,2);
tagstruct.Photometric = Tiff.Photometric.MinIsBlack;
tagstruct.BitsPerSample = 32;
tagstruct.SamplesPerPixel = 2;  % n_bands
tagstruct.RowsPerStrip = 1;
% tagstruct.Compression = Tiff.Compression.LZW;
tagstruct.PlanarConfiguration = Tiff.PlanarConfiguration.Separate;
tagstruct.SampleFormat = Tiff.SampleFormat.IEEEFP;
tagstruct.Software = 'MATLAB';
tagstruct % display tagstruct
setTag(t,tagstruct)
% t.write(uint8(b1_sub * 1000))
% t.write(uint8(b1_rest * 1000))

% n = numberOfStrips(t);
% im1 = single(b1_sub);
t.write(single(zeros(2, 2, 2)))
% for i = 1:size(b1_sub, 1)
%     writeEncodedStrip(t, i, single(b1_sub(i, :)))
% end
t.close()

t = Tiff('test.tif', 'r+');
% im2 = uint16(b1_rest * 1000);
for i = 1:size(b1_rest, 1)
    i_stripe = i + size(b1_sub, 1);
    writeEncodedStrip(t, i_stripe, single(b1_rest(i, :)))
end
% writeEncodedStrip(t, [2 3], uint8(b1_rest * 1000))
t.close()

imagesc(imread('test.tif'))
% imagesc(b1)