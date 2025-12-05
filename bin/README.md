## `bin/`

Save your custom scripts here. **Ensure these scripts are executable**. You can set the executable permission using:
```
chmod 770 <script_name>
```

In your `main.nf` or `module/<process.nf>` scripts, you can directly call the scripts placed in the `bin/` directory as if they were any other command line tool. E.g. for `module/example.nf`, run a script called `your_script.sh`, `example.nf` would have to contain the following:

```
process example {
    input:
    path input_file

    output:
    path output_file

    script:
    """
    your_script.sh $input_file \
      > $output_file
    """
}
```
